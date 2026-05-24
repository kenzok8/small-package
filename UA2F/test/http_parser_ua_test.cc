#include <cstring>
#include <limits>
#include <gtest/gtest.h>

extern "C" {
#include <http_parser_ua.h>
#include <http_session.h>
}

class HttpParserUATest : public ::testing::Test {
protected:
    struct http_session *session = nullptr;

    void SetUp() override {
        init_http_sessions(0);
        session_wrlock();
        struct session_key key = session_key_from_connid(1);
        session = session_create(&key);
        session_wrunlock();
        ASSERT_NE(session, nullptr);
        http_parser_init_session(session);
    }

    void TearDown() override {
        session_wrlock();
        session_cleanup_expired(-1);
        session_wrunlock();
        session = nullptr;
    }

    // Helper: set tcp_payload_base, then feed data into parser
    int feed(const char *data) {
        session_reset_per_packet(session, data);
        return http_parser_feed(session, data, strlen(data));
    }
};

// 1. Single packet with User-Agent
TEST_F(HttpParserUATest, SinglePacketWithUA) {
    const char *req = "GET / HTTP/1.1\r\nHost: example.com\r\nUser-Agent: Mozilla/5.0\r\n\r\n";
    int ret = feed(req);
    EXPECT_EQ(ret, 0);
    ASSERT_EQ(session->ua_entry_count, 1);

    // Verify offset points to "Mozilla/5.0"
    const char *ua_start = req + session->ua_entries[0].offset;
    EXPECT_EQ(strncmp(ua_start, "Mozilla/5.0", 11), 0);
    EXPECT_EQ(session->ua_entries[0].len, 11u);
}

// 2. Single packet with no User-Agent
TEST_F(HttpParserUATest, SinglePacketNoUA) {
    const char *req = "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n";
    int ret = feed(req);
    EXPECT_EQ(ret, 0);
    EXPECT_EQ(session->ua_entry_count, 0);
}

// 3. Case-insensitive User-Agent matching
TEST_F(HttpParserUATest, CaseInsensitiveUA) {
    const char *req = "GET / HTTP/1.1\r\nHost: example.com\r\nuser-agent: TestAgent\r\n\r\n";
    int ret = feed(req);
    EXPECT_EQ(ret, 0);
    ASSERT_EQ(session->ua_entry_count, 1);

    const char *ua_start = req + session->ua_entries[0].offset;
    EXPECT_EQ(strncmp(ua_start, "TestAgent", 9), 0);
    EXPECT_EQ(session->ua_entries[0].len, 9u);
}

// 4. Non-HTTP data should cause a parse error
TEST_F(HttpParserUATest, NonHttpData) {
    const char garbage[] = "\x00\x01\x02\x03\xff\xfe\xfd binary garbage data that is not HTTP at all!!!";
    session_reset_per_packet(session, garbage);
    int ret = http_parser_feed(session, garbage, sizeof(garbage) - 1);
    EXPECT_EQ(ret, -1);
}

// 5. Cross-packet UA field name split
TEST_F(HttpParserUATest, CrossPacketUAFieldName) {
    // First packet ends mid-field-name
    const char *pkt1 = "GET / HTTP/1.1\r\nHost: example.com\r\nUser-Ag";
    session_reset_per_packet(session, pkt1);
    int ret1 = http_parser_feed(session, pkt1, strlen(pkt1));
    EXPECT_EQ(ret1, 0);

    // Second packet completes the field name and provides the value
    const char *pkt2 = "ent: Mozilla/5.0\r\n\r\n";
    session_reset_per_packet(session, pkt2);
    int ret2 = http_parser_feed(session, pkt2, strlen(pkt2));
    EXPECT_EQ(ret2, 0);

    // The UA value appears in the second packet
    ASSERT_EQ(session->ua_entry_count, 1);
    const char *ua_start = pkt2 + session->ua_entries[0].offset;
    EXPECT_EQ(strncmp(ua_start, "Mozilla/5.0", 11), 0);
    EXPECT_EQ(session->ua_entries[0].len, 11u);
}

// 6. Cross-packet UA value split
TEST_F(HttpParserUATest, CrossPacketUAValue) {
    // First packet has start of UA value
    const char *pkt1 = "GET / HTTP/1.1\r\nUser-Agent: Mozilla/5.";
    session_reset_per_packet(session, pkt1);
    int ret1 = http_parser_feed(session, pkt1, strlen(pkt1));
    EXPECT_EQ(ret1, 0);
    // First packet should have found the partial UA
    EXPECT_EQ(session->ua_entry_count, 1);
    EXPECT_EQ(session->ua_entries[0].replacement_offset, 0u);

    // Second packet has the rest of the UA value
    const char *pkt2 = "0 (Windows)\r\n\r\n";
    session_reset_per_packet(session, pkt2);
    int ret2 = http_parser_feed(session, pkt2, strlen(pkt2));
    EXPECT_EQ(ret2, 0);

    // Second packet should also have recorded its portion
    EXPECT_EQ(session->ua_entry_count, 1);
    // The second packet's entry offset should point to "0 (Windows)"
    const char *ua_start2 = pkt2 + session->ua_entries[0].offset;
    EXPECT_EQ(strncmp(ua_start2, "0 (Windows)", 11), 0);
    EXPECT_EQ(session->ua_entries[0].replacement_offset, 10u);
}

TEST_F(HttpParserUATest, UaValueSeenLengthSaturatesOnOverflow) {
    const char *pkt1 = "GET / HTTP/1.1\r\nUser-Agent: A";
    session_reset_per_packet(session, pkt1);
    int ret1 = http_parser_feed(session, pkt1, strlen(pkt1));
    EXPECT_EQ(ret1, 0);
    ASSERT_EQ(session->ua_entry_count, 1);

    session->ua_value_seen_len = std::numeric_limits<size_t>::max() - 1;

    const char *pkt2 = "BC";
    session_reset_per_packet(session, pkt2);
    int ret2 = http_parser_feed(session, pkt2, strlen(pkt2));
    EXPECT_EQ(ret2, 0);
    ASSERT_EQ(session->ua_entry_count, 1);
    EXPECT_EQ(session->ua_entries[0].replacement_offset, std::numeric_limits<size_t>::max() - 1);
    EXPECT_EQ(session->ua_value_seen_len, std::numeric_limits<size_t>::max());
}

// 7. Keep-alive: multiple requests fed sequentially (separate feed calls)
TEST_F(HttpParserUATest, KeepAliveMultipleRequests) {
    const char *req1 = "GET /first HTTP/1.1\r\nHost: example.com\r\nUser-Agent: AgentOne\r\n\r\n";
    int ret1 = feed(req1);
    EXPECT_EQ(ret1, 0);
    EXPECT_EQ(session->ua_entry_count, 1);
    const char *ua1 = req1 + session->ua_entries[0].offset;
    EXPECT_EQ(strncmp(ua1, "AgentOne", 8), 0);

    const char *req2 = "GET /second HTTP/1.1\r\nHost: example.com\r\nUser-Agent: AgentTwo\r\n\r\n";
    int ret2 = feed(req2);
    EXPECT_EQ(ret2, 0);
    EXPECT_EQ(session->ua_entry_count, 1);
    const char *ua2 = req2 + session->ua_entries[0].offset;
    EXPECT_EQ(strncmp(ua2, "AgentTwo", 8), 0);
}

// 8. Pipelined requests in a single packet — both UAs should be recorded
TEST_F(HttpParserUATest, PipelinedRequestsSinglePacket) {
    const char *req = "GET /first HTTP/1.1\r\nHost: example.com\r\nUser-Agent: AgentOne\r\n\r\n"
                      "GET /second HTTP/1.1\r\nHost: example.com\r\nUser-Agent: AgentTwo\r\n\r\n";
    int ret = feed(req);
    EXPECT_EQ(ret, 0);
    EXPECT_EQ(session->ua_entry_count, 2);

    // First entry points into req
    const char *ua1 = req + session->ua_entries[0].offset;
    EXPECT_EQ(strncmp(ua1, "AgentOne", 8), 0);

    // Second entry points into req
    const char *ua2 = req + session->ua_entries[1].offset;
    EXPECT_EQ(strncmp(ua2, "AgentTwo", 8), 0);
}

// 9. Long field name (> FIELD_BUF_SIZE) should be ignored; UA after it still found
TEST_F(HttpParserUATest, LongFieldNameIgnored) {
    // Field name longer than 32 chars (FIELD_BUF_SIZE)
    const char *req = "GET / HTTP/1.1\r\n"
                      "X-Very-Long-Custom-Header-Name-That-Exceeds-Limit: somevalue\r\n"
                      "User-Agent: BrowserAgent\r\n"
                      "\r\n";
    int ret = feed(req);
    EXPECT_EQ(ret, 0);
    ASSERT_EQ(session->ua_entry_count, 1);
    const char *ua_start = req + session->ua_entries[0].offset;
    EXPECT_EQ(strncmp(ua_start, "BrowserAgent", 12), 0);
    EXPECT_EQ(session->ua_entries[0].len, 12u);
}

// 10. Multiple non-UA headers before User-Agent — verify field_buf resets correctly
TEST_F(HttpParserUATest, MultipleNonUAHeadersThenUA) {
    const char *req = "GET / HTTP/1.1\r\n"
                      "Host: example.com\r\n"
                      "Accept: text/html\r\n"
                      "Connection: keep-alive\r\n"
                      "User-Agent: TargetAgent\r\n"
                      "\r\n";
    int ret = feed(req);
    EXPECT_EQ(ret, 0);
    ASSERT_EQ(session->ua_entry_count, 1);
    const char *ua_start = req + session->ua_entries[0].offset;
    EXPECT_EQ(strncmp(ua_start, "TargetAgent", 11), 0);
    EXPECT_EQ(session->ua_entries[0].len, 11u);
}
