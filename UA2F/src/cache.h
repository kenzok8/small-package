#ifndef UA2F_CACHE_H
#define UA2F_CACHE_H

#include <stdbool.h>
#include <time.h>
#include "third/uthash.h"

#define CACHE_TIMEOUT 127
#define CACHE_CHECK_INTERVAL 128

#define INET6_ADDRSTRLEN 46
// 1111:1111:1111:1111:1111:1111:111.111.111.111:65535
// with null terminator
#define MAX_ADDR_PORT_LENGTH (INET6_ADDRSTRLEN + 7)

struct cache {
    char addr_port[MAX_ADDR_PORT_LENGTH];
    time_t last_time;
    UT_hash_handle hh;
};

void init_not_http_cache();

// add addr_port to cache, assume it's not a http dst
void cache_add(const char* addr_port);

bool cache_contains(const char* addr_port);

#endif //UA2F_CACHE_H
