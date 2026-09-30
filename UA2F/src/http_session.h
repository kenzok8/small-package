#ifndef UA2F_HTTP_SESSION_H
#define UA2F_HTTP_SESSION_H

#include <pthread.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <time.h>

#include "third/llhttp/llhttp.h"
#include "third/nfqueue-mnl/nfqueue-mnl.h"
#include "third/uthash/uthash.h"
#include "third/uthash/utarray.h"

#define UA_INLINE_ENTRIES 8
#define FIELD_BUF_SIZE 32

struct ua_mangle_entry {
    size_t offset;
    size_t len;
    size_t replacement_offset;
};

/* Uniform key for uthash — tagged union so both conn_id and tuple share same hash key field. */
struct session_key {
    bool use_conn_id;
    union {
        uint32_t conn_id;
        struct ip_tuple tuple;
    };
};

struct http_session {
    struct session_key key;

    pthread_mutex_t state_lock;
    bool state_lock_initialized;
    int ref_count;
    bool deleting;

    llhttp_t parser;

    char field_buf[FIELD_BUF_SIZE];
    int field_buf_len;
    bool field_matched;
    bool field_too_long;
    bool field_ua_candidate; // current header could still be "User-Agent"
    bool field_decided;      // field_ua_candidate has been set for this field

    bool last_was_value;
    bool in_ua_value;
    size_t ua_value_seen_len;

    // Keep the common case allocation-free; grow for large batches of headers.
    struct ua_mangle_entry ua_entries_inline[UA_INLINE_ENTRIES];
    UT_array ua_entries_overflow;
    size_t ua_entry_count;
    bool ua_allocation_failed; // fail closed until this session is destroyed/reinitialized

    const void *tcp_payload_base;

    time_t last_active;
    UT_hash_handle hh;
};

// Entry storage is split: the first eight slots are inline, the rest are utarray-owned.
static inline struct ua_mangle_entry *session_ua_entry(struct http_session *session, size_t index) {
    if (index < UA_INLINE_ENTRIES) {
        return &session->ua_entries_inline[index];
    }
    return (struct ua_mangle_entry *)utarray_eltptr(&session->ua_entries_overflow, index - UA_INLINE_ENTRIES);
}

static inline const struct ua_mangle_entry *session_ua_entry_const(const struct http_session *session, size_t index) {
    if (index < UA_INLINE_ENTRIES) {
        return &session->ua_entries_inline[index];
    }
    return (const struct ua_mangle_entry *)utarray_eltptr(&session->ua_entries_overflow, index - UA_INLINE_ENTRIES);
}

void init_http_sessions(int max_sessions);
struct session_key session_key_from_connid(uint32_t conn_id);
struct session_key session_key_from_tuple(const struct ip_tuple *tuple);
struct http_session *session_find(const struct session_key *key);
struct http_session *session_create(const struct session_key *key);
bool session_retain_locked(struct http_session *session);
void session_release(struct http_session *session);
void session_delete(struct http_session *session);
void session_delete_by_key(const struct session_key *key);
int session_count(void);
int session_cleanup_expired(int ttl_seconds);
void session_wrlock(void);
void session_wrunlock(void);
bool session_state_init(struct http_session *session);
// Release parser entry storage and, if initialized, the state mutex.
void session_state_destroy(struct http_session *session);
void session_state_lock(struct http_session *session);
void session_state_unlock(struct http_session *session);
void session_reset_per_packet(struct http_session *session, const void *tcp_payload_base);
void session_reset_per_message(struct http_session *session);

#endif /* UA2F_HTTP_SESSION_H */
