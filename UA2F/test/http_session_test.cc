#include <gtest/gtest.h>
#include <cstring>

extern "C" {
#include <http_session.h>
#include <http_parser_ua.h>
}

class HttpSessionTest : public ::testing::Test {
protected:
    void SetUp() override {
        init_http_sessions(0); // 0 = no limit by default; individual tests override via re-init
    }

    void TearDown() override {
        // Clean up all sessions
        session_wrlock();
        session_cleanup_expired(-1);
        session_wrunlock();
    }
};

TEST_F(HttpSessionTest, InitiallyEmpty) {
    EXPECT_EQ(session_count(), 0);
}

TEST_F(HttpSessionTest, CreateByConnId) {
    session_wrlock();
    struct session_key key = session_key_from_connid(42);
    struct http_session *s = session_create(&key);
    session_wrunlock();

    ASSERT_NE(s, nullptr);
    EXPECT_TRUE(s->key.use_conn_id);
    EXPECT_EQ(s->key.conn_id, 42u);
}

TEST_F(HttpSessionTest, FindByConnId) {
    session_wrlock();
    struct session_key key = session_key_from_connid(42);
    session_create(&key);
    struct http_session *found = session_find(&key);
    session_wrunlock();

    ASSERT_NE(found, nullptr);
    EXPECT_TRUE(found->key.use_conn_id);
    EXPECT_EQ(found->key.conn_id, 42u);
}

TEST_F(HttpSessionTest, FindNotFound) {
    session_wrlock();
    struct session_key key = session_key_from_connid(999);
    struct http_session *found = session_find(&key);
    session_wrunlock();

    EXPECT_EQ(found, nullptr);
}

TEST_F(HttpSessionTest, CreateByTuple) {
    struct ip_tuple tuple;
    memset(&tuple, 0, sizeof(tuple));
    tuple.ip_version = 4;
    tuple.src.ip4 = 0x01020304;
    tuple.dst.ip4 = 0x05060708;
    tuple.src_port = 12345;
    tuple.dst_port = 80;

    session_wrlock();
    struct session_key key = session_key_from_tuple(&tuple);
    struct http_session *s = session_create(&key);
    session_wrunlock();

    ASSERT_NE(s, nullptr);
    EXPECT_FALSE(s->key.use_conn_id);
    EXPECT_EQ(s->key.tuple.ip_version, 4);
    EXPECT_EQ(s->key.tuple.src.ip4, 0x01020304u);
    EXPECT_EQ(s->key.tuple.dst_port, 80u);
}

TEST_F(HttpSessionTest, FindByTuple) {
    struct ip_tuple tuple;
    memset(&tuple, 0, sizeof(tuple));
    tuple.ip_version = 4;
    tuple.src.ip4 = 0x0a000001;
    tuple.dst.ip4 = 0x0a000002;
    tuple.src_port = 54321;
    tuple.dst_port = 80;

    session_wrlock();
    struct session_key key = session_key_from_tuple(&tuple);
    session_create(&key);
    struct http_session *found = session_find(&key);
    session_wrunlock();

    ASSERT_NE(found, nullptr);
    EXPECT_FALSE(found->key.use_conn_id);
    EXPECT_EQ(found->key.tuple.src_port, 54321u);
}

TEST_F(HttpSessionTest, DeleteByKey) {
    session_wrlock();
    struct session_key key = session_key_from_connid(7);
    session_create(&key);
    EXPECT_EQ(session_count(), 1);
    session_delete_by_key(&key);
    EXPECT_EQ(session_count(), 0);
    session_wrunlock();
}

TEST_F(HttpSessionTest, DeleteRetainedSessionDefersFreeUntilRelease) {
    session_wrlock();
    struct session_key key = session_key_from_connid(8);
    struct http_session *s = session_create(&key);
    ASSERT_NE(s, nullptr);
    ASSERT_TRUE(session_retain_locked(s));
    EXPECT_EQ(session_count(), 1);

    session_delete(s);
    EXPECT_EQ(session_count(), 0);
    EXPECT_TRUE(s->deleting);
    EXPECT_EQ(s->key.conn_id, 8u);
    session_wrunlock();

    session_release(s);
}

TEST_F(HttpSessionTest, SessionLimit) {
    // Re-init with limit of 2
    init_http_sessions(2);

    session_wrlock();

    struct session_key k1 = session_key_from_connid(1);
    struct session_key k2 = session_key_from_connid(2);
    struct session_key k3 = session_key_from_connid(3);

    struct http_session *s1 = session_create(&k1);
    struct http_session *s2 = session_create(&k2);
    struct http_session *s3 = session_create(&k3);

    session_wrunlock();

    EXPECT_NE(s1, nullptr);
    EXPECT_NE(s2, nullptr);
    EXPECT_EQ(s3, nullptr);
    EXPECT_EQ(session_count(), 2);
}

TEST_F(HttpSessionTest, CleanupExpired) {
    session_wrlock();

    struct session_key k1 = session_key_from_connid(10);
    struct session_key k2 = session_key_from_connid(11);

    struct http_session *s1 = session_create(&k1);
    struct http_session *s2 = session_create(&k2);

    ASSERT_NE(s1, nullptr);
    ASSERT_NE(s2, nullptr);

    // Backdate s1's last_active so it appears expired
    s1->last_active = time(NULL) - 100;
    // s2 stays recent

    int deleted = session_cleanup_expired(10); // TTL = 10 seconds

    session_wrunlock();

    EXPECT_EQ(deleted, 1);
    EXPECT_EQ(session_count(), 1);
}

TEST_F(HttpSessionTest, ResetPerPacket) {
    session_wrlock();
    struct session_key key = session_key_from_connid(20);
    struct http_session *s = session_create(&key);
    ASSERT_NE(s, nullptr);

    s->ua_entry_count = 5;
    s->tcp_payload_base = nullptr;

    const char fake_payload[] = "GET / HTTP/1.1\r\n";
    session_reset_per_packet(s, fake_payload);

    session_wrunlock();

    EXPECT_EQ(s->ua_entry_count, 0);
    EXPECT_EQ(s->tcp_payload_base, fake_payload);
}

TEST_F(HttpSessionTest, ResetPerMessage) {
    session_wrlock();
    struct session_key key = session_key_from_connid(30);
    struct http_session *s = session_create(&key);
    ASSERT_NE(s, nullptr);

    // Set non-zero state
    s->field_buf_len = 10;
    s->field_matched = true;
    s->field_too_long = true;
    s->last_was_value = true;
    s->in_ua_value = true;

    session_reset_per_message(s);

    session_wrunlock();

    EXPECT_EQ(s->field_buf_len, 0);
    EXPECT_FALSE(s->field_matched);
    EXPECT_FALSE(s->field_too_long);
    EXPECT_FALSE(s->last_was_value);
    EXPECT_FALSE(s->in_ua_value);
}

class HttpSessionActivityTest : public HttpSessionTest {
protected:
    void expect_fragment_keeps_session(const char *start, const char *fragment) {
        session_wrlock();
        const auto active_key = session_key_from_connid(50);
        const auto idle_key = session_key_from_connid(51);
        auto *active = session_create(&active_key);
        auto *idle = session_create(&idle_key);
        session_wrunlock();
        ASSERT_NE(active, nullptr);
        ASSERT_NE(idle, nullptr);
        http_parser_init_session(active);

        session_state_lock(active);
        session_reset_per_packet(active, start);
        const int start_result = http_parser_feed(active, start, strlen(start));
        session_state_unlock(active);
        ASSERT_EQ(start_result, 0);

        const auto stale_time = time(nullptr) - 301;
        idle->last_active = stale_time;
        session_state_lock(active);
        active->last_active = stale_time;
        session_reset_per_packet(active, fragment);
        const int fragment_result = http_parser_feed(active, fragment, strlen(fragment));
        const auto last_active = active->last_active;
        session_state_unlock(active);
        ASSERT_EQ(fragment_result, 0);
        EXPECT_GT(last_active, stale_time);

        session_wrlock();
        EXPECT_EQ(session_cleanup_expired(300), 1);
        EXPECT_EQ(session_find(&active_key), active);
        EXPECT_EQ(session_find(&idle_key), nullptr);
        session_wrunlock();
    }
};

TEST_F(HttpSessionActivityTest, ContentLengthBodyProgressRefreshesIdleTtl) {
    expect_fragment_keeps_session("POST / HTTP/1.1\r\nContent-Length: 100000\r\n\r\n", "body fragment");
}

TEST_F(HttpSessionActivityTest, ChunkedBodyProgressRefreshesIdleTtl) {
    expect_fragment_keeps_session("POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n10000\r\n", "body fragment");
}

TEST_F(HttpSessionActivityTest, HeaderFieldProgressRefreshesIdleTtl) {
    expect_fragment_keeps_session("GET / HTTP/1.1\r\nUser-", "Agent");
}

TEST_F(HttpSessionActivityTest, HeaderValueProgressRefreshesIdleTtl) {
    expect_fragment_keeps_session("GET / HTTP/1.1\r\nUser-Agent: Original", "Agent");
}

TEST_F(HttpSessionActivityTest, EmptyFeedDoesNotRefreshIdleTtl) {
    session_wrlock();
    const auto key = session_key_from_connid(52);
    auto *session = session_create(&key);
    session_wrunlock();
    ASSERT_NE(session, nullptr);
    http_parser_init_session(session);
    const auto stale_time = time(nullptr) - 301;
    session->last_active = stale_time;
    session_reset_per_packet(session, "");
    EXPECT_EQ(http_parser_feed(session, "", 0), 0);
    EXPECT_EQ(session->last_active, stale_time);
    session_wrlock();
    EXPECT_EQ(session_cleanup_expired(300), 1);
    session_wrunlock();
}
