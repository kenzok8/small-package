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

TEST_F(CacheTest, MultipleDifferentAddresses) {
    addr_port addr1{}, addr2{}, addr3{};
    addr1.addr.ip4 = 1001;
    addr1.port = 80;
    addr2.addr.ip4 = 1002;
    addr2.port = 443;
    addr3.addr.ip4 = 1003;
    addr3.port = 8080;
    
    // Initially none should be in cache
    EXPECT_FALSE(cache_contains(addr1));
    EXPECT_FALSE(cache_contains(addr2));
    EXPECT_FALSE(cache_contains(addr3));
    
    // Add all to cache
    cache_add(addr1);
    cache_add(addr2);
    cache_add(addr3);
    
    // All should now be in cache
    EXPECT_TRUE(cache_contains(addr1));
    EXPECT_TRUE(cache_contains(addr2));
    EXPECT_TRUE(cache_contains(addr3));
}

TEST_F(CacheTest, SameAddressDifferentPorts) {
    addr_port addr1{}, addr2{};
    addr1.addr.ip4 = 2000;
    addr1.port = 80;
    addr2.addr.ip4 = 2000;  // Same IP
    addr2.port = 443;       // Different port
    
    cache_add(addr1);
    
    EXPECT_TRUE(cache_contains(addr1));
    EXPECT_FALSE(cache_contains(addr2));  // Different port should not match
}

TEST_F(CacheTest, CacheRefreshOnAccess) {
    addr_port addr{};
    addr.addr.ip4 = 3000;
    addr.port = 80;
    
    cache_add(addr);
    EXPECT_TRUE(cache_contains(addr));
    
    // Access the cache multiple times - this should refresh the last_time
    for (int i = 0; i < 5; i++) {
        EXPECT_TRUE(cache_contains(addr));
        sleep(1);  // Small delay
    }
    
    // Should still be in cache after multiple accesses
    EXPECT_TRUE(cache_contains(addr));
}

TEST_F(CacheTest, DuplicateAddDoesNotCrash) {
    addr_port addr{};
    addr.addr.ip4 = 4000;
    addr.port = 80;
    
    // Add the same address multiple times
    cache_add(addr);
    cache_add(addr);
    cache_add(addr);
    
    EXPECT_TRUE(cache_contains(addr));
}