#include <gtest/gtest.h>
#include <algorithm>
#include <limits>
#include <string>

#include "alloc_tracker.h"

extern "C" {
#include <http_parser_ua.h>
#include <http_session.h>
}

namespace {

std::string request_with_uas(size_t count) {
    std::string request = "GET / HTTP/1.1\r\n";
    for (size_t i = 0; i < count; ++i) {
        request += "User-Agent: Original\r\n";
    }
    return request + "\r\n";
}

size_t allocation_count(const allocation_counts &counts) {
    return counts.malloc_calls + counts.calloc_calls + counts.realloc_calls;
}

class HttpParserUAAllocationTest : public ::testing::Test {
protected:
    struct http_session session{};

    void SetUp() override { http_parser_init_session(&session); }
    void TearDown() override { session_state_destroy(&session); }

    int feed(const std::string &request) {
        session_reset_per_packet(&session, request.data());
        return http_parser_feed(&session, request.data(), request.size());
    }
};

TEST_F(HttpParserUAAllocationTest, InitializeAndDestroyWithoutHeapAllocation) {
    struct http_session empty{};
    ua2f_test_alloc_begin(0);
    http_parser_init_session(&empty);
    session_state_destroy(&empty);
    const auto counts = ua2f_test_alloc_end();
    EXPECT_EQ(allocation_count(counts), 0u);
    EXPECT_EQ(counts.free_calls, 0u);
}

TEST_F(HttpParserUAAllocationTest, UpToEightEntriesNeedNoHeapAllocation) {
    for (size_t entries = 0; entries <= 8; ++entries) {
        const auto request = request_with_uas(entries);
        ua2f_test_alloc_begin(0);
        const int result = feed(request);
        const auto counts = ua2f_test_alloc_end();
        ASSERT_EQ(result, 0);
        EXPECT_EQ(allocation_count(counts), 0u);
        EXPECT_EQ(counts.free_calls, 0u);
        EXPECT_EQ(session.ua_entry_count, entries);
        EXPECT_EQ(session.ua_entries_overflow.d, nullptr);
    }
    ua2f_test_alloc_begin(0);
    session_state_destroy(&session);
    const auto counts = ua2f_test_alloc_end();
    EXPECT_EQ(allocation_count(counts), 0u);
    EXPECT_EQ(counts.free_calls, 0u);
}

TEST_F(HttpParserUAAllocationTest, NinthEntryAllocatesOnlyOverflowStorage) {
    const auto request = request_with_uas(9);
    ua2f_test_alloc_begin(0);
    const int result = feed(request);
    const auto counts = ua2f_test_alloc_end();
    ASSERT_EQ(result, 0);
    EXPECT_EQ(counts.realloc_calls, 1u);
    EXPECT_EQ(allocation_count(counts), 1u);
    EXPECT_EQ(utarray_len(&session.ua_entries_overflow), 1u);
    EXPECT_EQ(session_ua_entry(&session, 0), &session.ua_entries_inline[0]);
    EXPECT_EQ(session_ua_entry(&session, 7), &session.ua_entries_inline[7]);
    EXPECT_EQ(session_ua_entry(&session, 8), utarray_front(&session.ua_entries_overflow));

    ua2f_test_alloc_begin(0);
    session_state_destroy(&session);
    const auto destroy_counts = ua2f_test_alloc_end();
    EXPECT_EQ(allocation_count(destroy_counts), 0u);
    EXPECT_EQ(destroy_counts.free_calls, 1u);
}

TEST_F(HttpParserUAAllocationTest, OverflowCapacityIsReusedAcrossPayloads) {
    const auto large = request_with_uas(33);
    const auto small = request_with_uas(1);
    ASSERT_EQ(feed(large), 0);
    const auto *buffer = session.ua_entries_overflow.d;
    for (const auto *request : {&large, &small, &large}) {
        ua2f_test_alloc_begin(0);
        const int result = feed(*request);
        const auto counts = ua2f_test_alloc_end();
        ASSERT_EQ(result, 0);
        EXPECT_EQ(allocation_count(counts), 0u);
        EXPECT_EQ(counts.free_calls, 0u);
        EXPECT_EQ(session.ua_entries_overflow.d, buffer);
    }
}

TEST_F(HttpParserUAAllocationTest, FirstOverflowAllocationFailureIsRecoverableAndSticky) {
    const auto request = request_with_uas(9);
    ua2f_test_alloc_begin(1);
    const int result = feed(request);
    const auto counts = ua2f_test_alloc_end();
    EXPECT_EQ(result, HTTP_PARSER_NO_MEMORY);
    EXPECT_EQ(counts.realloc_calls, 1u);
    EXPECT_EQ(session.ua_entry_count, 8u);
    EXPECT_EQ(session.ua_entries_overflow.d, nullptr);
    EXPECT_EQ(session.ua_entries_overflow.n, 0u);
    EXPECT_EQ(utarray_len(&session.ua_entries_overflow), 0u);
    EXPECT_TRUE(session.ua_allocation_failed);

    ua2f_test_alloc_begin(0);
    const int retry_result = feed(request);
    session_state_destroy(&session);
    const auto retry_counts = ua2f_test_alloc_end();
    EXPECT_EQ(retry_result, HTTP_PARSER_NO_MEMORY);
    EXPECT_EQ(allocation_count(retry_counts), 0u);
    EXPECT_EQ(retry_counts.free_calls, 0u);
}

TEST_F(HttpParserUAAllocationTest, GrowthFailurePreservesExistingBufferAndCapacity) {
    const auto first = request_with_uas(16);
    const auto larger = request_with_uas(17);
    ASSERT_EQ(feed(first), 0);
    const auto *buffer = session.ua_entries_overflow.d;
    const auto capacity = session.ua_entries_overflow.n;

    ua2f_test_alloc_begin(1);
    const int result = feed(larger);
    const auto counts = ua2f_test_alloc_end();
    EXPECT_EQ(result, HTTP_PARSER_NO_MEMORY);
    EXPECT_EQ(counts.realloc_calls, 1u);
    EXPECT_EQ(session.ua_entries_overflow.d, buffer);
    EXPECT_EQ(session.ua_entries_overflow.n, capacity);
    EXPECT_EQ(utarray_len(&session.ua_entries_overflow), 8u);
    EXPECT_EQ(session.ua_entry_count, 16u);
    EXPECT_TRUE(session.ua_allocation_failed);

    ua2f_test_alloc_begin(0);
    session_state_destroy(&session);
    const auto destroy_counts = ua2f_test_alloc_end();
    EXPECT_EQ(allocation_count(destroy_counts), 0u);
    EXPECT_EQ(destroy_counts.free_calls, 1u);
}

TEST_F(HttpParserUAAllocationTest, RejectsCountAndGrowthOverflowBeforeAllocating) {
    const auto request = request_with_uas(1);
    const size_t byte_limit = SIZE_MAX / sizeof(struct ua_mangle_entry) - UA_INLINE_ENTRIES;
    const unsigned growth_limit = static_cast<unsigned>(
        std::min(static_cast<size_t>(std::numeric_limits<unsigned>::max() / 2), byte_limit / 2));
    for (const unsigned capacity : {std::numeric_limits<unsigned>::max(), growth_limit + 1}) {
        http_parser_init_session(&session);
        session_reset_per_packet(&session, request.data());
        session.ua_entry_count = UA_INLINE_ENTRIES;
        session.ua_entries_overflow.i = capacity;
        session.ua_entries_overflow.n = capacity;
        ua2f_test_alloc_begin(0);
        const int result = http_parser_feed(&session, request.data(), request.size());
        const auto counts = ua2f_test_alloc_end();
        EXPECT_EQ(result, HTTP_PARSER_NO_MEMORY);
        EXPECT_EQ(allocation_count(counts), 0u);
        EXPECT_TRUE(session.ua_allocation_failed);
        session.ua_entries_overflow.i = 0;
        session.ua_entries_overflow.n = 0;
    }
}

} // namespace
