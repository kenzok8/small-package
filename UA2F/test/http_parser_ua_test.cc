#include <cstring>
#include <limits>
#include <string>
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
    const char *ua_start = req + session_ua_entry(session, 0)->offset;
    EXPECT_EQ(strncmp(ua_start, "Mozilla/5.0", 11), 0);
    EXPECT_EQ(session_ua_entry(session, 0)->len, 11u);
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

    const char *ua_start = req + session_ua_entry(session, 0)->offset;
    EXPECT_EQ(strncmp(ua_start, "TestAgent", 9), 0);
    EXPECT_EQ(session_ua_entry(session, 0)->len, 9u);
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
    const char *ua_start = pkt2 + session_ua_entry(session, 0)->offset;
    EXPECT_EQ(strncmp(ua_start, "Mozilla/5.0", 11), 0);
    EXPECT_EQ(session_ua_entry(session, 0)->len, 11u);
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
    EXPECT_EQ(session_ua_entry(session, 0)->replacement_offset, 0u);

    // Second packet has the rest of the UA value
    const char *pkt2 = "0 (Windows)\r\n\r\n";
    session_reset_per_packet(session, pkt2);
    int ret2 = http_parser_feed(session, pkt2, strlen(pkt2));
    EXPECT_EQ(ret2, 0);

    // Second packet should also have recorded its portion
    EXPECT_EQ(session->ua_entry_count, 1);
    // The second packet's entry offset should point to "0 (Windows)"
    const char *ua_start2 = pkt2 + session_ua_entry(session, 0)->offset;
    EXPECT_EQ(strncmp(ua_start2, "0 (Windows)", 11), 0);
    EXPECT_EQ(session_ua_entry(session, 0)->replacement_offset, 10u);
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
    EXPECT_EQ(session_ua_entry(session, 0)->replacement_offset, std::numeric_limits<size_t>::max() - 1);
    EXPECT_EQ(session->ua_value_seen_len, std::numeric_limits<size_t>::max());
}

// 7. Keep-alive: multiple requests fed sequentially (separate feed calls)
TEST_F(HttpParserUATest, KeepAliveMultipleRequests) {
    const char *req1 = "GET /first HTTP/1.1\r\nHost: example.com\r\nUser-Agent: AgentOne\r\n\r\n";
    int ret1 = feed(req1);
    EXPECT_EQ(ret1, 0);
    EXPECT_EQ(session->ua_entry_count, 1);
    const char *ua1 = req1 + session_ua_entry(session, 0)->offset;
    EXPECT_EQ(strncmp(ua1, "AgentOne", 8), 0);

    const char *req2 = "GET /second HTTP/1.1\r\nHost: example.com\r\nUser-Agent: AgentTwo\r\n\r\n";
    int ret2 = feed(req2);
    EXPECT_EQ(ret2, 0);
    EXPECT_EQ(session->ua_entry_count, 1);
    const char *ua2 = req2 + session_ua_entry(session, 0)->offset;
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
    const char *ua1 = req + session_ua_entry(session, 0)->offset;
    EXPECT_EQ(strncmp(ua1, "AgentOne", 8), 0);

    // Second entry points into req
    const char *ua2 = req + session_ua_entry(session, 1)->offset;
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
    const char *ua_start = req + session_ua_entry(session, 0)->offset;
    EXPECT_EQ(strncmp(ua_start, "BrowserAgent", 12), 0);
    EXPECT_EQ(session_ua_entry(session, 0)->len, 12u);
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
    const char *ua_start = req + session_ua_entry(session, 0)->offset;
    EXPECT_EQ(strncmp(ua_start, "TargetAgent", 11), 0);
    EXPECT_EQ(session_ua_entry(session, 0)->len, 11u);
}

TEST_F(HttpParserUATest, RecordsAllPipelinedRequestsBeyondInlineCapacity) {
    for (const size_t count : {9u, 32u, 257u}) {
        std::string requests;
        for (size_t i = 0; i < count; ++i) {
            requests += "GET / HTTP/1.1\r\nUser-Agent: Original" + std::to_string(i) + "\r\n\r\n";
        }
        ASSERT_EQ(feed(requests.c_str()), 0);
        ASSERT_EQ(session->ua_entry_count, count);
        for (size_t i = 0; i < count; ++i) {
            const auto &entry = *session_ua_entry(session, i);
            EXPECT_EQ(requests.substr(entry.offset, entry.len), "Original" + std::to_string(i));
            EXPECT_EQ(entry.replacement_offset, 0u);
        }
    }
}

TEST_F(HttpParserUATest, RecordsAllDuplicateUaHeadersBeyondInlineCapacity) {
    std::string request = "GET / HTTP/1.1\r\n";
    for (size_t i = 0; i < 1000; ++i) {
        request += "User-Agent: X\r\n";
    }
    request += "\r\n";
    ASSERT_EQ(feed(request.c_str()), 0);
    ASSERT_EQ(session->ua_entry_count, 1000u);
    for (size_t i = 0; i < session->ua_entry_count; ++i) {
        const auto &entry = *session_ua_entry(session, i);
        EXPECT_EQ(request.substr(entry.offset, entry.len), "X");
        EXPECT_EQ(entry.replacement_offset, 0u);
    }

    // Storage can be reused without carrying entries into the next payload.
    const auto *entries = session->ua_entries_overflow.d;
    ASSERT_EQ(feed("GET / HTTP/1.1\r\nUser-Agent: Next\r\n\r\n"), 0);
    EXPECT_EQ(session->ua_entries_overflow.d, entries);
    EXPECT_EQ(session->ua_entry_count, 1u);
}

TEST_F(HttpParserUATest, ContinuesSplitUaAfterGrowingEntries) {
    std::string request = "GET / HTTP/1.1\r\n";
    for (size_t i = 0; i < 8; ++i) {
        request += "User-Agent: First\r\n";
    }
    request += "User-Agent: Ninth";
    ASSERT_EQ(feed(request.c_str()), 0);
    ASSERT_EQ(session->ua_entry_count, 9u);
    EXPECT_EQ(session_ua_entry(session, 8)->len, 5u);

    ASSERT_EQ(feed("Agent\r\nUser-Agent: Tenth\r\n\r\n"), 0);
    ASSERT_EQ(session->ua_entry_count, 2u);
    EXPECT_EQ(session_ua_entry(session, 0)->offset, 0u);
    EXPECT_EQ(session_ua_entry(session, 0)->len, 5u);
    EXPECT_EQ(session_ua_entry(session, 0)->replacement_offset, 5u);
    EXPECT_EQ(session_ua_entry(session, 1)->replacement_offset, 0u);
}

TEST_F(HttpParserUATest, EntryCapacityOverflowIsNotAParseErrorOrSuccess) {
    const char *request = "GET / HTTP/1.1\r\nUser-Agent: Original\r\n\r\n";
    session_reset_per_packet(session, request);
    // Exercise the allocation size guard without attempting an enormous allocation.
    session->ua_entries_overflow.n = std::numeric_limits<unsigned>::max();
    session->ua_entries_overflow.i = session->ua_entries_overflow.n;
    session->ua_entry_count = UA_INLINE_ENTRIES;
    EXPECT_EQ(http_parser_feed(session, request, strlen(request)), HTTP_PARSER_NO_MEMORY);
    EXPECT_TRUE(session->ua_allocation_failed);
    session->ua_entries_overflow.n = 0;
    session->ua_entries_overflow.i = 0;
}

TEST(HttpParserStandaloneTest, ReleasesGrownEntriesWithoutStateMutex) {
    struct http_session session{};
    http_parser_init_session(&session);
    std::string request = "GET / HTTP/1.1\r\n";
    for (size_t i = 0; i < 33; ++i) {
        request += "User-Agent: Original\r\n";
    }
    request += "\r\n";
    session_reset_per_packet(&session, request.data());
    EXPECT_EQ(http_parser_feed(&session, request.data(), request.size()), 0);
    EXPECT_FALSE(session.state_lock_initialized);
    EXPECT_NE(session.ua_entries_overflow.d, nullptr);
    session_state_destroy(&session);
    EXPECT_EQ(session.ua_entries_overflow.d, nullptr);
    EXPECT_EQ(session.ua_entry_count, 0u);
    session_state_destroy(&session); // repeated destruction is harmless
}

TEST_F(HttpParserUATest, AllocationFailurePersistsAcrossPayloads) {
    const char *request = "GET / HTTP/1.1\r\nUser-Agent: Original\r\n\r\n";
    session_reset_per_packet(session, request);
    session->ua_entries_overflow.n = std::numeric_limits<unsigned>::max();
    session->ua_entries_overflow.i = session->ua_entries_overflow.n;
    session->ua_entry_count = UA_INLINE_ENTRIES;
    ASSERT_EQ(http_parser_feed(session, request, strlen(request)), HTTP_PARSER_NO_MEMORY);
    session->ua_entries_overflow.n = 0;
    session->ua_entries_overflow.i = 0;

    const auto stale_time = time(nullptr) - 301;
    session->last_active = stale_time;
    EXPECT_EQ(feed("Original\r\n\r\n"), HTTP_PARSER_NO_MEMORY);
    EXPECT_TRUE(session->ua_allocation_failed);
    EXPECT_GT(session->last_active, stale_time);
    EXPECT_EQ(feed(request), HTTP_PARSER_NO_MEMORY);

    http_parser_init_session(session);
    EXPECT_EQ(feed(request), 0);
    EXPECT_FALSE(session->ua_allocation_failed);
    EXPECT_EQ(session->ua_entry_count, 1u);
}
