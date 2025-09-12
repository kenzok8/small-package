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

TEST(HttpProtocolTest, AllHttpMethods) {
    // Test all supported HTTP methods
    EXPECT_TRUE(is_http_protocol("GET /", 5));
    EXPECT_TRUE(is_http_protocol("POST /", 6));
    EXPECT_TRUE(is_http_protocol("OPTIONS /", 9));
    EXPECT_TRUE(is_http_protocol("HEAD /", 6));
    EXPECT_TRUE(is_http_protocol("PUT /", 5));
    EXPECT_TRUE(is_http_protocol("DELETE /", 8));
    EXPECT_TRUE(is_http_protocol("TRACE /", 7));
    EXPECT_TRUE(is_http_protocol("CONNECT /", 9));
}

TEST(HttpProtocolTest, EdgeCases) {
    // Empty payload
    EXPECT_FALSE(is_http_protocol("", 0));
    
    // Too short for any method
    EXPECT_FALSE(is_http_protocol("G", 1));
    EXPECT_FALSE(is_http_protocol("GE", 2));
    
    // Incomplete methods
    EXPECT_FALSE(is_http_protocol("GE", 2));
    EXPECT_FALSE(is_http_protocol("POS", 3));
    
    // Case sensitivity
    EXPECT_FALSE(is_http_protocol("get /", 5));
    EXPECT_FALSE(is_http_protocol("Post /", 6));
    
    // Non-HTTP protocols
    EXPECT_FALSE(is_http_protocol("FTP /", 5));
    EXPECT_FALSE(is_http_protocol("SSH /", 5));
    EXPECT_FALSE(is_http_protocol("HTTPS /", 7));
}

TEST(MemNCaseMemTest, CaseInsensitiveSearch) {
    const char *l = "HELLO WORLD";
    size_t l_len = 11;
    
    // Test case insensitive matching
    EXPECT_EQ(memncasemem(l, l_len, "hello", 5), (void *)l);
    EXPECT_EQ(memncasemem(l, l_len, "HELLO", 5), (void *)l);
    EXPECT_EQ(memncasemem(l, l_len, "HeLLo", 5), (void *)l);
    EXPECT_EQ(memncasemem(l, l_len, "world", 5), (void *)(l + 6));
    EXPECT_EQ(memncasemem(l, l_len, "WORLD", 5), (void *)(l + 6));
    EXPECT_EQ(memncasemem(l, l_len, "WoRLd", 5), (void *)(l + 6));
}

TEST(MemNCaseMemTest, NotFoundCases) {
    const char *l = "Hello World";
    size_t l_len = 11;
    
    // Search for non-existent strings
    EXPECT_EQ(memncasemem(l, l_len, "xyz", 3), nullptr);
    EXPECT_EQ(memncasemem(l, l_len, "foo", 3), nullptr);
    EXPECT_EQ(memncasemem(l, l_len, "hello world!", 12), nullptr);  // Longer than haystack
}

TEST(MemNCaseMemTest, MultipleOccurrences) {
    const char *l = "hello hello hello";
    size_t l_len = 17;
    
    // Should find the first occurrence
    void *result = memncasemem(l, l_len, "hello", 5);
    EXPECT_EQ(result, (void *)l);
    
    // Search from different starting positions
    void *result2 = memncasemem(l + 6, l_len - 6, "hello", 5);
    EXPECT_EQ(result2, (void *)(l + 6));
}