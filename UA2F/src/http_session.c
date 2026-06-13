#include "http_session.h"

#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syslog.h>
#include <time.h>

static struct http_session *sessions = NULL;
static pthread_rwlock_t session_table_lock;
static bool session_table_lock_initialized = false;
static int max_session_count = 0;
static int current_session_count = 0;

static void session_free_final(struct http_session *session) {
    if (session == NULL) {
        return;
    }
    session_state_destroy(session);
    free(session);
}

static void session_free_all_unlocked(void) {
    struct http_session *cur, *tmp;
    HASH_ITER(hh, sessions, cur, tmp) {
        session_delete(cur);
    }
    sessions = NULL;
    current_session_count = 0;
}

void init_http_sessions(int max_sessions) {
    if (session_table_lock_initialized) {
        pthread_rwlock_wrlock(&session_table_lock);
        session_free_all_unlocked();
        pthread_rwlock_unlock(&session_table_lock);
        pthread_rwlock_destroy(&session_table_lock);
        session_table_lock_initialized = false;
    }

    max_session_count = max_sessions;
    current_session_count = 0;
    sessions = NULL;

    if (pthread_rwlock_init(&session_table_lock, NULL) != 0) {
        syslog(LOG_ERR, "Failed to init http_session lock");
        exit(EXIT_FAILURE);
    }
    session_table_lock_initialized = true;
}

struct session_key session_key_from_connid(uint32_t conn_id) {
    struct session_key key;
    memset(&key, 0, sizeof(key));
    key.use_conn_id = true;
    key.conn_id = conn_id;
    return key;
}

struct session_key session_key_from_tuple(const struct ip_tuple *tuple) {
    struct session_key key;
    memset(&key, 0, sizeof(key));
    key.use_conn_id = false;
    memcpy(&key.tuple, tuple, sizeof(struct ip_tuple));
    return key;
}

struct http_session *session_find(const struct session_key *key) {
    struct http_session *s = NULL;
    HASH_FIND(hh, sessions, key, sizeof(struct session_key), s);
    return s;
}

struct http_session *session_create(const struct session_key *key) {
    if (max_session_count > 0 && current_session_count >= max_session_count) {
        return NULL;
    }

    struct http_session *s = calloc(1, sizeof(struct http_session));
    if (s == NULL) {
        return NULL;
    }
    if (!session_state_init(s)) {
        free(s);
        return NULL;
    }

    memcpy(&s->key, key, sizeof(struct session_key));
    s->last_active = time(NULL);

    HASH_ADD(hh, sessions, key, sizeof(struct session_key), s);
    current_session_count++;

    return s;
}

bool session_retain_locked(struct http_session *session) {
    if (session == NULL || session->deleting) {
        return false;
    }

    session->ref_count++;
    return true;
}

void session_release(struct http_session *session) {
    if (session == NULL) {
        return;
    }

    struct http_session *free_me = NULL;
    session_wrlock();
    if (session->ref_count > 0) {
        session->ref_count--;
        if (session->ref_count == 0 && session->deleting) {
            free_me = session;
        }
    } else {
        syslog(LOG_ERR, "Attempted to release unreferenced HTTP session");
    }
    session_wrunlock();

    session_free_final(free_me);
}

void session_delete(struct http_session *session) {
    if (session == NULL) {
        return;
    }
    if (session->deleting) {
        return;
    }
    HASH_DEL(sessions, session);
    current_session_count--;
    session->deleting = true;
    if (session->ref_count == 0) {
        session_free_final(session);
    }
}

void session_delete_by_key(const struct session_key *key) {
    struct http_session *s = session_find(key);
    if (s != NULL) {
        session_delete(s);
    }
}

int session_count(void) { return current_session_count; }

int session_cleanup_expired(int ttl_seconds) {
    const time_t now = time(NULL);
    int deleted = 0;

    struct http_session *cur, *tmp;
    HASH_ITER(hh, sessions, cur, tmp) {
        bool expired = ttl_seconds < 0;
        if (!expired) {
            session_state_lock(cur);
            expired = difftime(now, cur->last_active) > ttl_seconds;
            session_state_unlock(cur);
        }
        if (expired) {
            session_delete(cur);
            deleted++;
        }
    }

    return deleted;
}

void session_wrlock(void) { pthread_rwlock_wrlock(&session_table_lock); }

void session_wrunlock(void) { pthread_rwlock_unlock(&session_table_lock); }

bool session_state_init(struct http_session *session) {
    if (session == NULL) {
        return false;
    }
    if (session->state_lock_initialized) {
        return true;
    }
    if (pthread_mutex_init(&session->state_lock, NULL) != 0) {
        syslog(LOG_ERR, "Failed to init http_session state lock");
        return false;
    }
    session->state_lock_initialized = true;
    return true;
}

void session_state_destroy(struct http_session *session) {
    if (session == NULL || !session->state_lock_initialized) {
        return;
    }
    pthread_mutex_destroy(&session->state_lock);
    session->state_lock_initialized = false;
}

void session_state_lock(struct http_session *session) {
    if (session != NULL && session->state_lock_initialized) {
        pthread_mutex_lock(&session->state_lock);
    }
}

void session_state_unlock(struct http_session *session) {
    if (session != NULL && session->state_lock_initialized) {
        pthread_mutex_unlock(&session->state_lock);
    }
}

void session_reset_per_packet(struct http_session *session, const void *tcp_payload_base) {
    session->ua_entry_count = 0;
    session->tcp_payload_base = tcp_payload_base;
    // last_active is updated in session_create and by the cleaner's TTL check.
    // Avoid time() syscall on every packet — the TTL is coarse (300s default).
}

void session_reset_per_message(struct http_session *session) {
    session->field_buf_len = 0;
    session->field_matched = false;
    session->field_too_long = false;
    session->field_ua_candidate = true;
    session->field_decided = false;
    session->last_was_value = false;
    session->in_ua_value = false;
    session->ua_value_seen_len = 0;
}
