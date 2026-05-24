#include <gtest/gtest.h>
#include <cstring>

extern "C" {
#include <http_session.h>
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
