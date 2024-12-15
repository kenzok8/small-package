#include "cache.h"
#include "third/uthash.h"

#include <pthread.h>
#include <stdbool.h>
#include <sys/syslog.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

pthread_rwlock_t cacheLock;

struct cache *not_http_dst_cache = NULL;
static int check_interval;

_Noreturn static void* check_cache(void* arg __attribute__((unused))) {
    while (true) {
        pthread_rwlock_wrlock(&cacheLock);

        const time_t now = time(NULL);
        struct cache *cur, *tmp;

        HASH_ITER(hh, not_http_dst_cache, cur, tmp) {
            if (difftime(now, cur->last_time) > check_interval) {
                HASH_DEL(not_http_dst_cache, cur);
                free(cur);
            }
        }

        pthread_rwlock_unlock(&cacheLock);

        sleep(check_interval);
    }
}

void init_not_http_cache(const int interval) {
    check_interval = interval;

    if (pthread_rwlock_init(&cacheLock, NULL) != 0) {
        syslog(LOG_ERR, "Failed to init cache lock");
        exit(EXIT_FAILURE);
    }
    syslog(LOG_INFO, "Cache lock initialized");

    pthread_t cleanup_thread;
    const __auto_type ret = pthread_create(&cleanup_thread, NULL, check_cache, NULL);
    if (ret) {
        syslog(LOG_ERR, "Failed to create cleanup thread: %d", ret);
        exit(EXIT_FAILURE);
    }
    syslog(LOG_INFO, "Cleanup thread created");

    pthread_detach(cleanup_thread);
}

bool cache_contains(struct addr_port target) {
    pthread_rwlock_wrlock(&cacheLock);

    struct cache *s;
    HASH_FIND(hh, not_http_dst_cache, &target, sizeof(struct addr_port), s);
    if (s != NULL) {
        s->last_time = time(NULL);
    }

    pthread_rwlock_unlock(&cacheLock);

    return s != NULL;
}

void cache_add(struct addr_port addr_port) {
    pthread_rwlock_wrlock(&cacheLock);

    struct cache *s;

    HASH_FIND(hh, not_http_dst_cache, &addr_port, sizeof(struct addr_port), s);
    if (s == NULL) {
        s = malloc(sizeof(struct cache));
        memcpy(&s->target.addr, &addr_port, sizeof(struct addr_port));
        HASH_ADD(hh, not_http_dst_cache, target.addr, sizeof(struct addr_port), s);
    }
    s->last_time = time(NULL);

    pthread_rwlock_unlock(&cacheLock);
}
