#include <gtest/gtest.h>

extern "C" {
#include <util.h>
}

TEST(MemNCaseMemTest, EmptyInput) {
    const char *l = "hello";
    size_t l_len = 0;
    const char *s = "";
    size_t s_len = 0;

    void *result = memncasemem(l, l_len, s, s_len);

    EXPECT_EQ(result, nullptr);
}

TEST(MemNCaseMemTest, SGreaterThanL) {
    const char *l = "hello";
    size_t l_len = 5;
    const char *s = "world";
    size_t s_len = 6;

    void *result = memncasemem(l, l_len, s, s_len);

    EXPECT_EQ(result, nullptr);
}

TEST(MemNCaseMemTest, SLengthOne) {
    const char *l = "hello";
    size_t l_len = 5;
    const char *s = "e";
    size_t s_len = 1;

    void *result = memncasemem(l, l_len, s, s_len);

    EXPECT_EQ(result, (void *) (l + 1));
}

// 测试正常情况
TEST(MemNCaseMemTest, NormalCase) {
    const char *l = "Hello, World!";
    size_t l_len = 13;
    const char *s = "world";
    size_t s_len = 5;

    void *result = memncasemem(l, l_len, s, s_len);

    EXPECT_EQ(result, (void *) (l + 7));
}

TEST(MemNCaseMemTest, UserAgentNormal) {
    const char *l = "\r\nUser-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)";
    size_t l_len = 95;
    const char *s = "\r\nUser-Agent:";
    size_t s_len = 13;

    void *result = memncasemem(l, l_len, s, s_len);

    EXPECT_EQ(result, (void *) l);
}

TEST(MemNCaseMemTest, UserAgentStrange) {
    const char *l = "\r\nuser-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)";
    size_t l_len = 95;
    const char *s = "\r\nUser-Agent:";
    size_t s_len = 13;

    void *result = memncasemem(l, l_len, s, s_len);

    EXPECT_EQ(result, (void *) l);
}

TEST(HttpProtocolTest, RealWorldRequests) {
    const char* getPayload = "GET /index.html HTTP/1.1\r\nHost: example.com\r\n\r\n";
    const char* postPayload = "POST /submit HTTP/1.1\r\nHost: example.com\r\n\r\n";
    const char* optionsPayload = "OPTIONS /test HTTP/1.1\r\nHost: example.com\r\n\r\n";

    EXPECT_TRUE(is_http_protocol(getPayload, strlen(getPayload))) << "GET method failed";
    EXPECT_TRUE(is_http_protocol(postPayload, strlen(postPayload))) << "POST method failed";
    EXPECT_TRUE(is_http_protocol(optionsPayload, strlen(optionsPayload))) << "OPTIONS method failed";

    const char* invalidPayload = "INVALID string";

    // Check that these cases return false
    EXPECT_FALSE(is_http_protocol(invalidPayload, strlen(invalidPayload))) << "Invalid method passed";
}