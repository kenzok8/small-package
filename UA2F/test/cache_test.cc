#include <gtest/gtest.h>

extern "C" {
#include <cache.h>
}

class CacheTest : public ::testing::Test {
protected:
    addr_port test_addr{};

    void SetUp() override {
        test_addr.addr.ip4 = 12345;
        test_addr.port = 80;
        init_not_http_cache(1);
    }

    void TearDown() override {
        pthread_rwlock_wrlock(&cacheLock);
        // Clear the cache after each test
        cache *cur, *tmp;
        HASH_ITER(hh, not_http_dst_cache, cur, tmp) {
            HASH_DEL(not_http_dst_cache, cur);
            free(cur);
        }
        pthread_rwlock_unlock(&cacheLock);
    }
};

TEST_F(CacheTest, CacheInitiallyEmpty) {
    EXPECT_FALSE(cache_contains(test_addr));
}

TEST_F(CacheTest, AddToCache) {
    cache_add(test_addr);
    EXPECT_TRUE(cache_contains(test_addr));
}

TEST_F(CacheTest, AddAndRemoveFromCache) {
    cache_add(test_addr);
    EXPECT_TRUE(cache_contains(test_addr));
    sleep(5);
    EXPECT_FALSE(cache_contains(test_addr));
}

TEST_F(CacheTest, CacheDoesNotContainNonexistentEntry) {
    addr_port nonexistent_addr{};
    nonexistent_addr.addr.ip4 = 54321;
    EXPECT_FALSE(cache_contains(nonexistent_addr));
}