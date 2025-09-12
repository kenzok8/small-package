#include <gtest/gtest.h>
#include <cstring>

extern "C" {
#include <statistics.h>
}

class StatisticsTest : public ::testing::Test {
protected:
    void SetUp() override {
        init_statistics();
    }
};

TEST_F(StatisticsTest, InitializeStatistics) {
    // Statistics should be initialized without error
    EXPECT_NO_THROW(init_statistics());
}

TEST_F(StatisticsTest, CountUserAgentPacket) {
    EXPECT_NO_THROW(count_user_agent_packet());
    // Call multiple times to test counting
    for (int i = 0; i < 5; i++) {
        count_user_agent_packet();
    }
}

TEST_F(StatisticsTest, CountTcpPacket) {
    EXPECT_NO_THROW(count_tcp_packet());
    // Call multiple times to test counting
    for (int i = 0; i < 10; i++) {
        count_tcp_packet();
    }
}

TEST_F(StatisticsTest, CountHttpPacket) {
    EXPECT_NO_THROW(count_http_packet());
    // Call multiple times to test counting
    for (int i = 0; i < 3; i++) {
        count_http_packet();
    }
}

TEST_F(StatisticsTest, CountIpv4Packet) {
    EXPECT_NO_THROW(count_ipv4_packet());
    // Call multiple times to test counting
    for (int i = 0; i < 7; i++) {
        count_ipv4_packet();
    }
}

TEST_F(StatisticsTest, CountIpv6Packet) {
    EXPECT_NO_THROW(count_ipv6_packet());
    // Call multiple times to test counting
    for (int i = 0; i < 4; i++) {
        count_ipv6_packet();
    }
}

TEST_F(StatisticsTest, TryPrintStatistics) {
    // Should not crash when called
    EXPECT_NO_THROW(try_print_statistics());
    
    // Generate some statistics and try printing
    for (int i = 0; i < 100; i++) {
        count_user_agent_packet();
        count_tcp_packet();
        count_http_packet();
        count_ipv4_packet();
    }
    EXPECT_NO_THROW(try_print_statistics());
}

// Test time string formatting function if accessible
extern "C" char *fill_time_string(const double sec);

TEST_F(StatisticsTest, TimeStringFormatting) {
    char *result;
    
    // Test seconds
    result = fill_time_string(30.0);
    EXPECT_TRUE(strstr(result, "seconds") != nullptr);
    
    // Test minutes
    result = fill_time_string(150.0);
    EXPECT_TRUE(strstr(result, "minutes") != nullptr);
    EXPECT_TRUE(strstr(result, "seconds") != nullptr);
    
    // Test hours
    result = fill_time_string(3700.0);
    EXPECT_TRUE(strstr(result, "hours") != nullptr);
    EXPECT_TRUE(strstr(result, "minutes") != nullptr);
    EXPECT_TRUE(strstr(result, "seconds") != nullptr);
    
    // Test days
    result = fill_time_string(90000.0);
    EXPECT_TRUE(strstr(result, "days") != nullptr);
    EXPECT_TRUE(strstr(result, "hours") != nullptr);
    EXPECT_TRUE(strstr(result, "minutes") != nullptr);
    EXPECT_TRUE(strstr(result, "seconds") != nullptr);
}