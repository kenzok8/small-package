#include "http_parser_ua.h"

#include <pthread.h>
#include <string.h>
#include <strings.h>
#include <sys/syslog.h>
#include <time.h>

#include "statistics.h"
#include "third/llhttp/llhttp.h"

static int on_header_field(llhttp_t *parser, const char *data, size_t len) {
    struct http_session *session = (struct http_session *)parser->data;

    if (session->last_was_value) {
        // Transitioning from value to a new field — reset field state
        session->field_buf_len = 0;
        session->field_matched = false;
        session->field_too_long = false;
        session->field_ua_candidate = true;
        session->field_decided = false;
        session->in_ua_value = false;
        session->ua_value_seen_len = 0;
    }
    session->last_was_value = false;

    if (session->field_too_long) {
        return 0;
    }

    // "User-Agent" is the only header we care about. Decide from the field's
    // first byte (case-insensitive 'U') whether it can match; if not, skip the
    // buffering memcpy and the later strncasecmp for this field entirely. The
    // decision is made exactly once per field (field_decided) so a chunk
    // boundary cannot turn a non-matching name into a false positive.
    if (!session->field_decided && len > 0) {
        session->field_ua_candidate = (data[0] == 'U' || data[0] == 'u');
        session->field_decided = true;
    }
    if (!session->field_ua_candidate) {
        return 0;
    }

    if ((size_t)(FIELD_BUF_SIZE - session->field_buf_len) < len) {
        session->field_too_long = true;
        return 0;
    }

    memcpy(session->field_buf + session->field_buf_len, data, len);
    session->field_buf_len += (int)len;

    return 0;
}

static int on_header_value(llhttp_t *parser, const char *data, size_t len) {
    struct http_session *session = (struct http_session *)parser->data;

    if (!session->last_was_value) {
        // Just transitioned from field to value — check if it's User-Agent
        if (session->field_buf_len == 10 && strncasecmp(session->field_buf, "User-Agent", 10) == 0) {
            session->field_matched = true;
        } else {
            session->field_matched = false;
        }
    }
    session->last_was_value = true;

    if (!session->field_matched) {
        return 0;
    }

    if (session->tcp_payload_base == NULL) {
        return 0;
    }

    const uintptr_t data_addr = (uintptr_t)data;
    const uintptr_t base_addr = (uintptr_t)session->tcp_payload_base;
    if (data_addr < base_addr) {
        return 0;
    }
    size_t offset = (size_t)(data_addr - base_addr);

    if (session->in_ua_value && session->ua_entry_count > 0) {
        // Continuation of the same UA value — extend current entry
        size_t *entry_len = &session->ua_entries[session->ua_entry_count - 1].len;
        if (SIZE_MAX - *entry_len < len) {
            *entry_len = SIZE_MAX;
        } else {
            *entry_len += len;
        }
    } else {
        // New UA entry
        if (session->ua_entry_count < UA_MAX_ENTRIES) {
            session->ua_entries[session->ua_entry_count].offset = offset;
            session->ua_entries[session->ua_entry_count].len = len;
            session->ua_entries[session->ua_entry_count].replacement_offset = session->ua_value_seen_len;
            session->ua_entry_count++;
        }
        session->in_ua_value = true;
    }

    if (SIZE_MAX - session->ua_value_seen_len < len) {
        session->ua_value_seen_len = SIZE_MAX;
    } else {
        session->ua_value_seen_len += len;
    }

    return 0;
}

static int on_headers_complete(llhttp_t *parser) {
    struct http_session *session = (struct http_session *)parser->data;
    session_reset_per_message(session);
    count_http_packet();
    return 0;
}

static int on_message_complete(llhttp_t *parser) {
    struct http_session *session = (struct http_session *)parser->data;
    session_reset_per_message(session);
    session->last_active = time(NULL);
    return 0;
}

static llhttp_settings_t shared_settings;
static pthread_once_t settings_once = PTHREAD_ONCE_INIT;

static void init_shared_settings(void) {
    llhttp_settings_init(&shared_settings);
    shared_settings.on_header_field = on_header_field;
    shared_settings.on_header_value = on_header_value;
    shared_settings.on_headers_complete = on_headers_complete;
    shared_settings.on_message_complete = on_message_complete;
}

void http_parser_init_session(struct http_session *session) {
    pthread_once(&settings_once, init_shared_settings);

    llhttp_init(&session->parser, HTTP_REQUEST, &shared_settings);
    session->parser.data = session;

    session_reset_per_message(session);
}

int http_parser_feed(struct http_session *session, const char *data, size_t len) {
    llhttp_errno_t err = llhttp_execute(&session->parser, data, len);
    if (err != HPE_OK) {
        syslog(LOG_DEBUG, "llhttp parse error: %s (%s)", llhttp_errno_name(err),
               llhttp_get_error_reason(&session->parser));
        return -1;
    }
    return 0;
}
