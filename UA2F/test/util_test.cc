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