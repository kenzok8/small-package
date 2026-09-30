// Compile the production proxy here for transport tests. This keeps its private
// event-loop API out of the installed headers, while testing the exact same C
// implementation (including lifecycle tests that call run_proxy).
#include "../src/proxy.c"
#include "proxy_transport.h"

struct proxy_test_connection {
    struct proxy_context ctx;
    struct proxy_connection *conn;
};

struct proxy_test_connection *proxy_test_create(int client_fd, int target_fd, bool splice_enabled, bool target_in_progress) {
    struct proxy_test_connection *test = calloc(1, sizeof(*test));
    if (test == NULL) {
        close(client_fd);
        close(target_fd);
        return NULL;
    }
    test->ctx.epoll_fd = epoll_create1(EPOLL_CLOEXEC);
    if (test->ctx.epoll_fd < 0 || !proxy_try_acquire_connection()) {
        if (test->ctx.epoll_fd >= 0) {
            close(test->ctx.epoll_fd);
        }
        close(client_fd);
        close(target_fd);
        free(test);
        return NULL;
    }
    test->conn = create_connection(&test->ctx, client_fd, target_fd, AF_INET, target_in_progress);
    if (test->conn == NULL) {
        close_all_connections(&test->ctx);
        close(test->ctx.epoll_fd);
        free(test);
        return NULL;
    }
    test->conn->rewrite_disabled = true;
    if (!splice_enabled) {
        test->conn->splice_enabled = false;
    } else if (!test->conn->splice_enabled || fcntl(test->conn->splice_pipe[0], F_SETPIPE_SZ, 4096) < 0) {
        proxy_test_destroy(test);
        return NULL;
    }
    return test;
}

void proxy_test_destroy(struct proxy_test_connection *test) {
    if (test != NULL) {
        close_all_connections(&test->ctx);
        close(test->ctx.epoll_fd);
        free(test);
    }
}

int proxy_test_step(struct proxy_test_connection *test, int timeout_ms) {
    struct epoll_event events[16];
    const int ready = epoll_wait(test->ctx.epoll_fd, events, 16, timeout_ms);
    if (ready < 0) {
        return -1;
    }
    for (int i = 0; i < ready; i++) {
        handle_connection_event(events[i].data.ptr, events[i].events);
    }
    // Retain closing connections until test destruction so assertions can inspect
    // EOF and pending-byte state after the descriptors have been closed.
    return ready;
}

struct proxy_test_state proxy_test_snapshot(const struct proxy_test_connection *test) {
    const struct proxy_connection *conn = test->conn;
    return (struct proxy_test_state){
        .client_eof = conn->client_eof,
        .target_eof = conn->target_eof,
        .client_write_shutdown = conn->client_write_shutdown,
        .target_write_shutdown = conn->target_write_shutdown,
        .closing = conn->closing,
        .splice_enabled = conn->splice_enabled,
        .target_connected = conn->target_connected,
        .client_registered = !conn->closing && conn->client_armed != PROXY_EVENTS_UNSET,
        .target_registered = !conn->closing && conn->target_armed != PROXY_EVENTS_UNSET,
        .client_events = conn->client_armed,
        .target_events = conn->target_armed,
        .request_pending = conn->client_to_target.len - conn->client_to_target.off,
        .response_pending = conn->target_to_client.len - conn->target_to_client.off,
        .splice_pending = conn->splice_pending,
    };
}
