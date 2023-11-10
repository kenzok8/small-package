#include "cache.h"
#include "third/uthash.h"

#include <pthread.h>
#include <sys/syslog.h>
#include <stdbool.h>
#include <unistd.h>

pthread_rwlock_t cacheLock;

struct cache *not_http_dst_cache = NULL;

_Noreturn static void check_cache() {
    while (true) {
        pthread_rwlock_wrlock(&cacheLock);

        const time_t now = time(NULL);
        struct cache *cur, *tmp;

        HASH_ITER(hh, not_http_dst_cache, cur, tmp) {
            if (difftime(now, cur->last_time) > CACHE_TIMEOUT) {
                HASH_DEL(not_http_dst_cache, cur);
                free(cur);
            }
        }

        pthread_rwlock_unlock(&cacheLock);

        // wait for 1 minute
        sleep(CACHE_CHECK_INTERVAL);
    }
}

void init_not_http_cache() {
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
}

bool cache_contains(const char* addr_port) {
    pthread_rwlock_rdlock(&cacheLock);

    struct cache *s;
    HASH_FIND_STR(not_http_dst_cache, addr_port, s);

    pthread_rwlock_unlock(&cacheLock);

    if (s != NULL) {
        bool ret;
        pthread_rwlock_wrlock(&cacheLock);
        if (difftime(time(NULL), s->last_time) > CACHE_TIMEOUT) {
            HASH_DEL(not_http_dst_cache, s);
            free(s);
            ret = false;
        } else {
            s->last_time = time(NULL);
            ret = true;
        }
        pthread_rwlock_unlock(&cacheLock);
        return ret;
    }

    return false;
}

void cache_add(const char *addr_port) {
    pthread_rwlock_wrlock(&cacheLock);

    struct cache *s;
    HASH_FIND_STR(not_http_dst_cache, addr_port, s);
    if (s != NULL) {
        s->last_time = time(NULL);
    } else {
        s = malloc(sizeof(struct cache));
        strcpy(s->addr_port, addr_port);
        s->last_time = time(NULL);
        HASH_ADD_STR(not_http_dst_cache, addr_port, s);
    }

    pthread_rwlock_unlock(&cacheLock);
}
