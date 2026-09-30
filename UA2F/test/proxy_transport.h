#ifndef UA2F_PROXY_TRANSPORT_TEST_H
#define UA2F_PROXY_TRANSPORT_TEST_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

struct proxy_test_connection;
struct proxy_test_state {
    bool client_eof, target_eof;
    bool client_write_shutdown, target_write_shutdown;
    bool closing, splice_enabled, target_connected;
    bool client_registered, target_registered;
    uint32_t client_events, target_events;
    size_t request_pending, response_pending, splice_pending;
};

// Takes ownership of both proxy-side descriptors, including on failure.
struct proxy_test_connection *proxy_test_create(int client_fd, int target_fd, bool splice_enabled, bool target_in_progress);
void proxy_test_destroy(struct proxy_test_connection *test);
int proxy_test_step(struct proxy_test_connection *test, int timeout_ms);
struct proxy_test_state proxy_test_snapshot(const struct proxy_test_connection *test);

#endif
