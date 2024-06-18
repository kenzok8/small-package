#ifndef UA2F_CACHE_H
#define UA2F_CACHE_H

#include <stdbool.h>
#include <time.h>
#include <pthread.h>

#include "third/nfqueue-mnl.h"
#include "third/uthash.h"

struct addr_port {
    ip_address_t addr;
    uint16_t port;
};

struct cache {
    struct addr_port target;
    time_t last_time;
    UT_hash_handle hh;
};

extern struct cache *not_http_dst_cache;
extern pthread_rwlock_t cacheLock;

void init_not_http_cache(int interval);

// add addr_port to cache, assume it's not a http dst
void cache_add(struct addr_port addr_port);

bool cache_contains(struct addr_port addr_port);

#endif // UA2F_CACHE_H
