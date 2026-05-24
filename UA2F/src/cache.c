#include "cache.h"
#include "third/uthash/uthash.h"

#include <errno.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syslog.h>
#include <time.h>

pthread_rwlock_t cacheLock;

struct cache *not_http_dst_cache = NULL;
static int check_interval;
static bool cache_initialized = false;
static bool cleanup_thread_started = false;
static bool cleanup_registered = false;
static bool cleanup_should_stop = false;
static pthread_t cleanup_thread;
static pthread_mutex_t cleanup_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t cleanup_cond = PTHREAD_COND_INITIALIZER;

static void cache_free_all_unlocked(void) {
    struct cache *cur, *tmp;
    HASH_ITER(hh, not_http_dst_cache, cur, tmp) {
        HASH_DEL(not_http_dst_cache, cur);
        free(cur);
    }
}

static void cache_delete_expired(void) {
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
}

static void wait_for_next_cleanup(void) {
    struct timespec deadline;
    clock_gettime(CLOCK_REALTIME, &deadline);
    deadline.tv_sec += check_interval;

    pthread_mutex_lock(&cleanup_mutex);
    while (!cleanup_should_stop) {
        if (pthread_cond_timedwait(&cleanup_cond, &cleanup_mutex, &deadline) == ETIMEDOUT) {
            break;
        }
    }
    pthread_mutex_unlock(&cleanup_mutex);
}

static void *check_cache(void *arg __attribute__((unused))) {
    for (;;) {
        cache_delete_expired();
        wait_for_next_cleanup();

        pthread_mutex_lock(&cleanup_mutex);
        const bool should_stop = cleanup_should_stop;
        pthread_mutex_unlock(&cleanup_mutex);
        if (should_stop) {
            return NULL;
        }
    }
}

void destroy_not_http_cache(void) {
    if (!cache_initialized) {
        return;
    }

    pthread_mutex_lock(&cleanup_mutex);
    cleanup_should_stop = true;
    pthread_cond_broadcast(&cleanup_cond);
    pthread_mutex_unlock(&cleanup_mutex);

    if (cleanup_thread_started) {
        pthread_join(cleanup_thread, NULL);
        cleanup_thread_started = false;
    }

    pthread_rwlock_wrlock(&cacheLock);
    cache_free_all_unlocked();
    pthread_rwlock_unlock(&cacheLock);

    pthread_rwlock_destroy(&cacheLock);
    cache_initialized = false;
    cleanup_should_stop = false;
    not_http_dst_cache = NULL;
}

void init_not_http_cache(const int interval) {
    if (cache_initialized) {
        destroy_not_http_cache();
    }

    check_interval = interval > 0 ? interval : 1;

    if (pthread_rwlock_init(&cacheLock, NULL) != 0) {
        syslog(LOG_ERR, "Failed to init cache lock");
        exit(EXIT_FAILURE);
    }
    cache_initialized = true;
    syslog(LOG_INFO, "Cache lock initialized");

    if (!cleanup_registered) {
        atexit(destroy_not_http_cache);
        cleanup_registered = true;
    }

    const __auto_type ret = pthread_create(&cleanup_thread, NULL, check_cache, NULL);
    if (ret) {
        syslog(LOG_ERR, "Failed to create cleanup thread: %d", ret);
        pthread_rwlock_destroy(&cacheLock);
        cache_initialized = false;
        exit(EXIT_FAILURE);
    }
    cleanup_thread_started = true;
    syslog(LOG_INFO, "Cleanup thread created");
}

bool cache_contains(struct addr_port target) {
    pthread_rwlock_rdlock(&cacheLock);

    struct cache *s;
    HASH_FIND(hh, not_http_dst_cache, &target, sizeof(struct addr_port), s);
    const bool found = (s != NULL);

    pthread_rwlock_unlock(&cacheLock);

    if (found) {
        pthread_rwlock_wrlock(&cacheLock);
        HASH_FIND(hh, not_http_dst_cache, &target, sizeof(struct addr_port), s);
        if (s != NULL) {
            s->last_time = time(NULL);
        }
        pthread_rwlock_unlock(&cacheLock);
    }

    return found;
}

void cache_add(struct addr_port addr_port) {
    struct cache *node = malloc(sizeof(struct cache));
    if (node == NULL) {
        return;
    }
    const time_t now = time(NULL);

    pthread_rwlock_wrlock(&cacheLock);

    struct cache *s;
    HASH_FIND(hh, not_http_dst_cache, &addr_port, sizeof(struct addr_port), s);
    if (s == NULL) {
        memcpy(&node->target.addr, &addr_port, sizeof(struct addr_port));
        node->last_time = now;
        HASH_ADD(hh, not_http_dst_cache, target.addr, sizeof(struct addr_port), node);
        node = NULL;
    } else {
        s->last_time = now;
    }

    pthread_rwlock_unlock(&cacheLock);

    free(node);
}
