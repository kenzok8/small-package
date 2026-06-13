#include "proxy.h"

#include "handler.h"
#include "http_parser_ua.h"
#include "http_session.h"
#include "statistics.h"
#ifdef UA2F_ENABLE_UCI
#include "config.h"
#endif

#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <pthread.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdatomic.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <syslog.h>
#include <unistd.h>

#ifndef SO_ORIGINAL_DST
#define SO_ORIGINAL_DST 80
#endif

#ifndef IP6T_SO_ORIGINAL_DST
#define IP6T_SO_ORIGINAL_DST 80
#endif

#ifndef IP_TRANSPARENT
#define IP_TRANSPARENT 19
#endif

#ifndef IPV6_TRANSPARENT
#define IPV6_TRANSPARENT 75
#endif

#ifndef SO_MARK
#define SO_MARK 36
#endif

#ifndef SO_REUSEPORT
#define SO_REUSEPORT 15
#endif

#define PROXY_BUFFER_SIZE 16384
#define PROXY_SPLICE_SIZE (1U << 20)
#define PROXY_MAX_CONNECTIONS 512
#define PROXY_MAX_EVENTS 128
#define PROXY_DEFAULT_WORKERS 4
#define PROXY_MAX_WORKERS 16

#ifndef SPLICE_F_NONBLOCK
#define SPLICE_F_NONBLOCK 0x02
#endif

#ifndef F_SETPIPE_SZ
#define F_SETPIPE_SZ 1031
#endif

struct proxy_context;
struct proxy_connection;
struct proxy_listener;

enum epoll_ref_type {
    EPOLL_REF_LISTENER = 1,
    EPOLL_REF_CONNECTION,
};

enum proxy_side {
    PROXY_SIDE_CLIENT = 1,
    PROXY_SIDE_TARGET,
};

struct epoll_ref {
    enum epoll_ref_type type;
    union {
        struct proxy_listener *listener;
        struct {
            struct proxy_connection *conn;
            enum proxy_side side;
        } connection;
    };
};

struct proxy_listener {
    int fd;
    int family;
    struct epoll_ref ref;
};

struct proxy_buffer {
    uint8_t data[PROXY_BUFFER_SIZE];
    size_t off;
    size_t len;
};

struct proxy_connection {
    struct proxy_context *ctx;
    struct proxy_connection *next;
    struct proxy_connection *close_next;

    int client_fd;
    int target_fd;
    int family;
    bool target_connected;
    bool client_eof;
    bool target_eof;
    bool target_write_shutdown;
    bool client_write_shutdown;
    bool rewrite_disabled;
    bool closing;
    bool splice_enabled;

    int splice_pipe[2];
    size_t splice_pending;

    struct http_session session;
    struct proxy_buffer client_to_target;
    struct proxy_buffer target_to_client;
    struct epoll_ref client_ref;
    struct epoll_ref target_ref;

    // Event mask currently armed on each fd; lets us skip redundant EPOLL_CTL_MOD.
    uint32_t client_armed;
    uint32_t target_armed;
};

#define PROXY_EVENTS_UNSET UINT32_MAX

struct proxy_context {
    int epoll_fd;
    struct proxy_connection *connections;
    struct proxy_connection *closing;
};

struct proxy_worker_args {
    enum ua2f_mode mode;
    uint16_t listen_port;
    volatile sig_atomic_t *should_exit;
    int worker_id;
    int worker_count;
    int result;
};

static atomic_int active_connections = 0;

static bool proxy_try_acquire_connection(void) {
    int current = atomic_load_explicit(&active_connections, memory_order_relaxed);
    while (current < PROXY_MAX_CONNECTIONS) {
        if (atomic_compare_exchange_weak_explicit(&active_connections, &current, current + 1, memory_order_relaxed,
                                                  memory_order_relaxed)) {
            return true;
        }
    }
    return false;
}

static void proxy_release_connection(void) {
    atomic_fetch_sub_explicit(&active_connections, 1, memory_order_relaxed);
}

static int set_nonblocking(int fd) {
    const int flags = fcntl(fd, F_GETFL, 0);
    if (flags < 0) {
        return -1;
    }
    return fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}

static int set_cloexec(int fd) {
    const int flags = fcntl(fd, F_GETFD, 0);
    if (flags < 0) {
        return -1;
    }
    return fcntl(fd, F_SETFD, flags | FD_CLOEXEC);
}

static void set_tcp_nodelay(int fd) {
    // Disabling Nagle avoids the delayed-ACK stall on the request/response ping-pong.
    const int one = 1;
    (void)setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one));
}

static ssize_t proxy_splice(int in_fd, int out_fd, size_t len) {
#ifdef SYS_splice
    return (ssize_t)syscall(SYS_splice, in_fd, NULL, out_fd, NULL, len, SPLICE_F_NONBLOCK);
#else
    (void)in_fd;
    (void)out_fd;
    (void)len;
    errno = ENOSYS;
    return -1;
#endif
}

static int create_splice_pipe(int pipe_fds[2]) {
    pipe_fds[0] = -1;
    pipe_fds[1] = -1;

#ifdef SYS_pipe2
    if (syscall(SYS_pipe2, pipe_fds, O_NONBLOCK | O_CLOEXEC) == 0) {
        goto configure_size;
    }
    if (errno != ENOSYS && errno != EINVAL) {
        return -1;
    }
#endif

    if (pipe(pipe_fds) != 0) {
        return -1;
    }
    if (set_nonblocking(pipe_fds[0]) != 0 || set_nonblocking(pipe_fds[1]) != 0 || set_cloexec(pipe_fds[0]) != 0 ||
        set_cloexec(pipe_fds[1]) != 0) {
        close(pipe_fds[0]);
        close(pipe_fds[1]);
        pipe_fds[0] = -1;
        pipe_fds[1] = -1;
        return -1;
    }

configure_size:
#ifdef F_SETPIPE_SZ
    (void)fcntl(pipe_fds[0], F_SETPIPE_SZ, (int)PROXY_SPLICE_SIZE);
#endif
    return 0;
}

static socklen_t sockaddr_size(const struct sockaddr_storage *addr) {
    switch (addr->ss_family) {
    case AF_INET:
        return sizeof(struct sockaddr_in);
    case AF_INET6:
        return sizeof(struct sockaddr_in6);
    default:
        return sizeof(*addr);
    }
}

static uint16_t sockaddr_port(const struct sockaddr_storage *addr) {
    if (addr->ss_family == AF_INET) {
        const struct sockaddr_in *in = (const struct sockaddr_in *)addr;
        return ntohs(in->sin_port);
    }
    if (addr->ss_family == AF_INET6) {
        const struct sockaddr_in6 *in6 = (const struct sockaddr_in6 *)addr;
        return ntohs(in6->sin6_port);
    }
    return 0;
}

static bool sockaddr_is_loopback(const struct sockaddr_storage *addr) {
    if (addr->ss_family == AF_INET) {
        const struct sockaddr_in *in = (const struct sockaddr_in *)addr;
        const uint32_t ip = ntohl(in->sin_addr.s_addr);
        return (ip >> 24) == 127;
    }
    if (addr->ss_family == AF_INET6) {
        const struct sockaddr_in6 *in6 = (const struct sockaddr_in6 *)addr;
        return IN6_IS_ADDR_LOOPBACK(&in6->sin6_addr);
    }
    return false;
}

static bool sockaddr_addr_equal(const struct sockaddr_storage *a, const struct sockaddr_storage *b) {
    if (a->ss_family != b->ss_family) {
        return false;
    }
    if (a->ss_family == AF_INET) {
        const struct sockaddr_in *in_a = (const struct sockaddr_in *)a;
        const struct sockaddr_in *in_b = (const struct sockaddr_in *)b;
        return in_a->sin_addr.s_addr == in_b->sin_addr.s_addr;
    }
    if (a->ss_family == AF_INET6) {
        const struct sockaddr_in6 *in6_a = (const struct sockaddr_in6 *)a;
        const struct sockaddr_in6 *in6_b = (const struct sockaddr_in6 *)b;
        return memcmp(&in6_a->sin6_addr, &in6_b->sin6_addr, sizeof(in6_a->sin6_addr)) == 0;
    }
    return false;
}

static bool sockaddr_endpoint_equal(const struct sockaddr_storage *a, const struct sockaddr_storage *b) {
    return sockaddr_port(a) == sockaddr_port(b) && sockaddr_addr_equal(a, b);
}

static bool sockaddr_matches_local_socket(int fd, const struct sockaddr_storage *dst) {
    struct sockaddr_storage local;
    memset(&local, 0, sizeof(local));
    socklen_t local_len = sizeof(local);
    if (getsockname(fd, (struct sockaddr *)&local, &local_len) != 0) {
        return false;
    }
    return sockaddr_endpoint_equal(&local, dst);
}

static bool should_drop_proxy_loop(int client_fd, enum ua2f_mode mode, const struct sockaddr_storage *dst,
                                   uint16_t listen_port) {
    if (sockaddr_port(dst) != listen_port) {
        return false;
    }
    if (sockaddr_is_loopback(dst)) {
        return true;
    }
    if (mode == UA2F_MODE_REDIRECT) {
        return sockaddr_matches_local_socket(client_fd, dst);
    }
    return true;
}

static void format_sockaddr(const struct sockaddr_storage *addr, char *buf, size_t buf_len) {
    char host[NI_MAXHOST] = {0};
    char service[NI_MAXSERV] = {0};

    if (getnameinfo((const struct sockaddr *)addr, sockaddr_size(addr), host, sizeof(host), service, sizeof(service),
                    NI_NUMERICHOST | NI_NUMERICSERV) != 0) {
        snprintf(buf, buf_len, "<unknown>");
        return;
    }

    if (addr->ss_family == AF_INET6) {
        snprintf(buf, buf_len, "[%s]:%s", host, service);
    } else {
        snprintf(buf, buf_len, "%s:%s", host, service);
    }
}

static bool proxy_buffer_pending(const struct proxy_buffer *buf) {
    return buf->off < buf->len;
}

static size_t proxy_buffer_space(const struct proxy_buffer *buf) {
    if (buf->off == buf->len) {
        return sizeof(buf->data);
    }
    return sizeof(buf->data) - buf->len;
}

static bool target_output_pending(const struct proxy_connection *conn) {
    return proxy_buffer_pending(&conn->target_to_client) || conn->splice_pending > 0;
}

static bool target_output_has_space(const struct proxy_connection *conn) {
    if (conn->splice_enabled) {
        return conn->splice_pending == 0;
    }
    return proxy_buffer_space(&conn->target_to_client) > 0;
}

static void proxy_buffer_compact(struct proxy_buffer *buf) {
    if (buf->off == 0) {
        return;
    }
    if (buf->off == buf->len) {
        buf->off = 0;
        buf->len = 0;
        return;
    }
    memmove(buf->data, buf->data + buf->off, buf->len - buf->off);
    buf->len -= buf->off;
    buf->off = 0;
}

static int epoll_set(int epoll_fd, int op, int fd, struct epoll_ref *ref, uint32_t events) {
    struct epoll_event event;
    memset(&event, 0, sizeof(event));
    event.events = events | EPOLLERR | EPOLLHUP | EPOLLRDHUP;
    event.data.ptr = ref;
    return epoll_ctl(epoll_fd, op, fd, &event);
}

// Re-arm an fd only when the desired interest mask differs from what is armed,
// avoiding an EPOLL_CTL_MOD syscall on every event in steady state.
static int epoll_rearm(int epoll_fd, int fd, struct epoll_ref *ref, uint32_t *armed, uint32_t desired) {
    if (*armed == desired) {
        return 0;
    }
    if (epoll_set(epoll_fd, EPOLL_CTL_MOD, fd, ref, desired) != 0) {
        return -1;
    }
    *armed = desired;
    return 0;
}

static void connection_schedule_close(struct proxy_connection *conn);
static void connection_update_events(struct proxy_connection *conn);

static void connection_add(struct proxy_context *ctx, struct proxy_connection *conn) {
    conn->next = ctx->connections;
    ctx->connections = conn;
}

static void connection_unlink(struct proxy_context *ctx, struct proxy_connection *conn) {
    struct proxy_connection **cur = &ctx->connections;
    while (*cur != NULL) {
        if (*cur == conn) {
            *cur = conn->next;
            conn->next = NULL;
            return;
        }
        cur = &(*cur)->next;
    }
}

static void free_closed_connections(struct proxy_context *ctx) {
    while (ctx->closing != NULL) {
        struct proxy_connection *conn = ctx->closing;
        ctx->closing = conn->close_next;
        connection_unlink(ctx, conn);
        free(conn);
    }
}

static void connection_schedule_close(struct proxy_connection *conn) {
    if (conn->closing) {
        return;
    }
    conn->closing = true;

    if (conn->client_fd >= 0) {
        epoll_ctl(conn->ctx->epoll_fd, EPOLL_CTL_DEL, conn->client_fd, NULL);
        close(conn->client_fd);
        conn->client_fd = -1;
    }
    if (conn->target_fd >= 0) {
        epoll_ctl(conn->ctx->epoll_fd, EPOLL_CTL_DEL, conn->target_fd, NULL);
        close(conn->target_fd);
        conn->target_fd = -1;
    }
    if (conn->splice_pipe[0] >= 0) {
        close(conn->splice_pipe[0]);
        conn->splice_pipe[0] = -1;
    }
    if (conn->splice_pipe[1] >= 0) {
        close(conn->splice_pipe[1]);
        conn->splice_pipe[1] = -1;
    }

    proxy_release_connection();
    conn->close_next = conn->ctx->closing;
    conn->ctx->closing = conn;
}

static void maybe_shutdown_writes(struct proxy_connection *conn) {
    if (conn->target_connected && conn->client_eof && !conn->target_write_shutdown &&
        !proxy_buffer_pending(&conn->client_to_target)) {
        shutdown(conn->target_fd, SHUT_WR);
        conn->target_write_shutdown = true;
    }
    if (conn->target_connected && conn->target_eof && !conn->client_write_shutdown &&
        !target_output_pending(conn)) {
        shutdown(conn->client_fd, SHUT_WR);
        conn->client_write_shutdown = true;
    }
}

static void connection_update_events(struct proxy_connection *conn) {
    if (conn->closing) {
        return;
    }

    maybe_shutdown_writes(conn);
    if (conn->client_eof && conn->target_eof && !proxy_buffer_pending(&conn->client_to_target) &&
        !target_output_pending(conn)) {
        connection_schedule_close(conn);
        return;
    }

    if (!conn->target_connected) {
        if (epoll_rearm(conn->ctx->epoll_fd, conn->target_fd, &conn->target_ref, &conn->target_armed, EPOLLOUT) != 0) {
            syslog(LOG_WARNING, "epoll target connect modify failed: %s", strerror(errno));
            connection_schedule_close(conn);
        }
        return;
    }

    uint32_t client_events = 0;
    uint32_t target_events = 0;
    if (!conn->client_eof && proxy_buffer_space(&conn->client_to_target) > 0) {
        client_events |= EPOLLIN;
    }
    if (target_output_pending(conn)) {
        client_events |= EPOLLOUT;
    }
    if (!conn->target_eof && target_output_has_space(conn)) {
        target_events |= EPOLLIN;
    }
    if (proxy_buffer_pending(&conn->client_to_target)) {
        target_events |= EPOLLOUT;
    }

    if (epoll_rearm(conn->ctx->epoll_fd, conn->client_fd, &conn->client_ref, &conn->client_armed, client_events) != 0) {
        syslog(LOG_WARNING, "epoll client modify failed: %s", strerror(errno));
        connection_schedule_close(conn);
        return;
    }
    if (epoll_rearm(conn->ctx->epoll_fd, conn->target_fd, &conn->target_ref, &conn->target_armed, target_events) != 0) {
        syslog(LOG_WARNING, "epoll target modify failed: %s", strerror(errno));
        connection_schedule_close(conn);
    }
}

static void rewrite_user_agent_entries(uint8_t *buf, size_t len, const struct http_session *session) {
    const char *replacement = get_replacement_user_agent_string();
    if (replacement == NULL) {
        return;
    }
    const size_t replacement_len = UA2F_MAX_USER_AGENT_LENGTH;

    for (int i = 0; i < session->ua_entry_count; i++) {
        const size_t offset = session->ua_entries[i].offset;
        const size_t ua_len = session->ua_entries[i].len;
        const size_t replacement_offset = session->ua_entries[i].replacement_offset;
        if (offset > len || ua_len > len - offset) {
            continue;
        }

        memset(buf + offset, ' ', ua_len);
        if (replacement_offset < replacement_len) {
            size_t available = replacement_len - replacement_offset;
            if (available > ua_len) {
                available = ua_len;
            }
            memcpy(buf + offset, replacement + replacement_offset, available);
        }
    }
}

static void process_client_payload(struct proxy_connection *conn, uint8_t *buf, size_t len) {
    if (conn->rewrite_disabled) {
        return;
    }

    count_tcp_packet();
    session_reset_per_packet(&conn->session, buf);
    const int parse_ret = http_parser_feed(&conn->session, (const char *)buf, len);
    if (conn->session.ua_entry_count > 0) {
        rewrite_user_agent_entries(buf, len, &conn->session);
        count_user_agent_packet();
    }

    try_print_statistics();

    if (parse_ret != 0) {
        conn->rewrite_disabled = true;
    }
}

static int flush_buffer(int fd, struct proxy_buffer *buf) {
    while (proxy_buffer_pending(buf)) {
        const ssize_t sent = send(fd, buf->data + buf->off, buf->len - buf->off, MSG_NOSIGNAL);
        if (sent < 0) {
            if (errno == EINTR) {
                continue;
            }
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                return 0;
            }
            return -1;
        }
        if (sent == 0) {
            return -1;
        }
        buf->off += (size_t)sent;
    }
    buf->off = 0;
    buf->len = 0;
    return 0;
}

static int read_into_buffer(struct proxy_connection *conn, enum proxy_side side) {
    struct proxy_buffer *out = side == PROXY_SIDE_CLIENT ? &conn->client_to_target : &conn->target_to_client;

    for (;;) {
        proxy_buffer_compact(out);
        size_t space = proxy_buffer_space(out);
        if (space == 0) {
            return 0;
        }

        const int fd = side == PROXY_SIDE_CLIENT ? conn->client_fd : conn->target_fd;
        const ssize_t n = recv(fd, out->data + out->len, space, 0);
        if (n == 0) {
            if (side == PROXY_SIDE_CLIENT) {
                conn->client_eof = true;
            } else {
                conn->target_eof = true;
            }
            return 0;
        }
        if (n < 0) {
            if (errno == EINTR) {
                continue;
            }
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                return 0;
            }
            return -1;
        }

        if (side == PROXY_SIDE_CLIENT) {
            process_client_payload(conn, out->data + out->len, (size_t)n);
        }
        out->len += (size_t)n;
    }
}

static int pump_splice_to_client(struct proxy_connection *conn) {
    while (conn->splice_pending > 0) {
        size_t len = conn->splice_pending;
        if (len > PROXY_SPLICE_SIZE) {
            len = PROXY_SPLICE_SIZE;
        }

        const ssize_t n = proxy_splice(conn->splice_pipe[0], conn->client_fd, len);
        if (n > 0) {
            conn->splice_pending -= (size_t)n;
            continue;
        }
        if (n == 0) {
            return -1;
        }
        if (errno == EINTR) {
            continue;
        }
        if (errno == EAGAIN || errno == EWOULDBLOCK) {
            return 0;
        }
        return -1;
    }
    return 0;
}

static int transfer_target_to_client(struct proxy_connection *conn) {
    if (!conn->splice_enabled) {
        return read_into_buffer(conn, PROXY_SIDE_TARGET);
    }

    for (;;) {
        if (pump_splice_to_client(conn) != 0) {
            return -1;
        }
        if (conn->splice_pending > 0) {
            return 0;
        }

        const ssize_t n = proxy_splice(conn->target_fd, conn->splice_pipe[1], PROXY_SPLICE_SIZE);
        if (n > 0) {
            conn->splice_pending = (size_t)n;
            continue;
        }
        if (n == 0) {
            conn->target_eof = true;
            return 0;
        }
        if (errno == EINTR) {
            continue;
        }
        if (errno == EAGAIN || errno == EWOULDBLOCK) {
            return 0;
        }
        if (errno == EINVAL || errno == ENOSYS) {
            conn->splice_enabled = false;
            return read_into_buffer(conn, PROXY_SIDE_TARGET);
        }
        return -1;
    }
}

static bool get_redirect_original_dst(int fd, int family, struct sockaddr_storage *dst, socklen_t *dst_len) {
    memset(dst, 0, sizeof(*dst));

    if (family == AF_INET) {
        struct sockaddr_in addr;
        socklen_t len = sizeof(addr);
        if (getsockopt(fd, IPPROTO_IP, SO_ORIGINAL_DST, &addr, &len) != 0) {
            syslog(LOG_WARNING, "getsockopt SO_ORIGINAL_DST failed: %s", strerror(errno));
            return false;
        }
        memcpy(dst, &addr, sizeof(addr));
        *dst_len = sizeof(addr);
        return true;
    }

    if (family == AF_INET6) {
        struct sockaddr_in6 addr6;
        socklen_t len = sizeof(addr6);
        if (getsockopt(fd, IPPROTO_IPV6, IP6T_SO_ORIGINAL_DST, &addr6, &len) != 0) {
            syslog(LOG_WARNING, "getsockopt IP6T_SO_ORIGINAL_DST failed: %s", strerror(errno));
            return false;
        }
        memcpy(dst, &addr6, sizeof(addr6));
        *dst_len = sizeof(addr6);
        return true;
    }

    return false;
}

static bool get_tproxy_original_dst(int fd, struct sockaddr_storage *dst, socklen_t *dst_len) {
    memset(dst, 0, sizeof(*dst));
    *dst_len = sizeof(*dst);
    if (getsockname(fd, (struct sockaddr *)dst, dst_len) != 0) {
        syslog(LOG_WARNING, "getsockname original destination failed: %s", strerror(errno));
        return false;
    }
    return true;
}

static int connect_target(const struct sockaddr_storage *dst, socklen_t dst_len, bool *in_progress) {
    *in_progress = false;
    const int fd = socket(dst->ss_family, SOCK_STREAM, 0);
    if (fd < 0) {
        syslog(LOG_WARNING, "socket target failed: %s", strerror(errno));
        return -1;
    }

    if (set_nonblocking(fd) != 0) {
        syslog(LOG_WARNING, "set target nonblocking failed: %s", strerror(errno));
        close(fd);
        return -1;
    }

    set_tcp_nodelay(fd);

    const int mark = UA2F_PROXY_SO_MARK;
    if (setsockopt(fd, SOL_SOCKET, SO_MARK, &mark, sizeof(mark)) != 0) {
        syslog(LOG_WARNING, "setsockopt SO_MARK failed: %s", strerror(errno));
        close(fd);
        return -1;
    }

    if (connect(fd, (const struct sockaddr *)dst, dst_len) != 0) {
        if (errno == EINPROGRESS) {
            *in_progress = true;
            return fd;
        }
        char dst_buf[128];
        format_sockaddr(dst, dst_buf, sizeof(dst_buf));
        syslog(LOG_WARNING, "connect target %s failed: %s", dst_buf, strerror(errno));
        close(fd);
        return -1;
    }

    return fd;
}

static bool finish_target_connect(struct proxy_connection *conn) {
    int error = 0;
    socklen_t error_len = sizeof(error);
    if (getsockopt(conn->target_fd, SOL_SOCKET, SO_ERROR, &error, &error_len) != 0) {
        syslog(LOG_WARNING, "getsockopt SO_ERROR failed: %s", strerror(errno));
        return false;
    }
    if (error != 0) {
        syslog(LOG_WARNING, "connect target failed: %s", strerror(error));
        return false;
    }

    conn->target_connected = true;
    if (epoll_set(conn->ctx->epoll_fd, EPOLL_CTL_ADD, conn->client_fd, &conn->client_ref, EPOLLIN) != 0) {
        syslog(LOG_WARNING, "epoll client add failed: %s", strerror(errno));
        return false;
    }
    conn->client_armed = EPOLLIN;
    return true;
}

static void handle_connection_event(struct epoll_ref *ref, uint32_t events) {
    struct proxy_connection *conn = ref->connection.conn;
    const enum proxy_side side = ref->connection.side;
    if (conn->closing) {
        return;
    }

    if (side == PROXY_SIDE_TARGET && !conn->target_connected) {
        if ((events & (EPOLLOUT | EPOLLERR | EPOLLHUP)) == 0) {
            return;
        }
        if (!finish_target_connect(conn)) {
            connection_schedule_close(conn);
            return;
        }
        connection_update_events(conn);
        return;
    }

    if (events & EPOLLOUT) {
        if (side == PROXY_SIDE_CLIENT) {
            if (flush_buffer(conn->client_fd, &conn->target_to_client) != 0 || pump_splice_to_client(conn) != 0) {
                connection_schedule_close(conn);
                return;
            }
        } else if (flush_buffer(conn->target_fd, &conn->client_to_target) != 0) {
            connection_schedule_close(conn);
            return;
        }
    }

    if (events & (EPOLLIN | EPOLLRDHUP)) {
        const int read_result =
            side == PROXY_SIDE_TARGET ? transfer_target_to_client(conn) : read_into_buffer(conn, side);
        if (read_result != 0) {
            connection_schedule_close(conn);
            return;
        }

        if (side == PROXY_SIDE_CLIENT && proxy_buffer_pending(&conn->client_to_target)) {
            if (flush_buffer(conn->target_fd, &conn->client_to_target) != 0) {
                connection_schedule_close(conn);
                return;
            }
        } else if (side == PROXY_SIDE_TARGET && !conn->splice_enabled && proxy_buffer_pending(&conn->target_to_client)) {
            if (flush_buffer(conn->client_fd, &conn->target_to_client) != 0) {
                connection_schedule_close(conn);
                return;
            }
        }
    }

    if ((events & (EPOLLERR | EPOLLHUP)) != 0) {
        if (side == PROXY_SIDE_CLIENT) {
            conn->client_eof = true;
        } else {
            conn->target_eof = true;
        }
    }

    connection_update_events(conn);
}

static int set_socket_int(int fd, int level, int option, int value, const char *name) {
    if (setsockopt(fd, level, option, &value, sizeof(value)) != 0) {
        syslog(LOG_WARNING, "setsockopt %s failed: %s", name, strerror(errno));
        return -1;
    }
    return 0;
}

static int create_listener(int family, enum ua2f_mode mode, uint16_t listen_port) {
    const int fd = socket(family, SOCK_STREAM, 0);
    if (fd < 0) {
        syslog(LOG_WARNING, "socket listener failed: %s", strerror(errno));
        return -1;
    }

    if (set_nonblocking(fd) != 0) {
        syslog(LOG_WARNING, "set listener nonblocking failed: %s", strerror(errno));
        close(fd);
        return -1;
    }

    if (set_socket_int(fd, SOL_SOCKET, SO_REUSEADDR, 1, "SO_REUSEADDR") != 0) {
        close(fd);
        return -1;
    }

    if (set_socket_int(fd, SOL_SOCKET, SO_REUSEPORT, 1, "SO_REUSEPORT") != 0) {
        close(fd);
        return -1;
    }

    if (family == AF_INET6 && set_socket_int(fd, IPPROTO_IPV6, IPV6_V6ONLY, 1, "IPV6_V6ONLY") != 0) {
        close(fd);
        return -1;
    }

    if (mode == UA2F_MODE_TPROXY) {
        if (family == AF_INET) {
            if (set_socket_int(fd, IPPROTO_IP, IP_TRANSPARENT, 1, "IP_TRANSPARENT") != 0) {
                close(fd);
                return -1;
            }
        } else if (set_socket_int(fd, IPPROTO_IPV6, IPV6_TRANSPARENT, 1, "IPV6_TRANSPARENT") != 0) {
            close(fd);
            return -1;
        }
    }

    if (family == AF_INET) {
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = htonl(INADDR_ANY);
        addr.sin_port = htons(listen_port);
        if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)) != 0) {
            syslog(LOG_WARNING, "bind IPv4 listener failed: %s", strerror(errno));
            close(fd);
            return -1;
        }
    } else {
        struct sockaddr_in6 addr6;
        memset(&addr6, 0, sizeof(addr6));
        addr6.sin6_family = AF_INET6;
        addr6.sin6_addr = in6addr_any;
        addr6.sin6_port = htons(listen_port);
        if (bind(fd, (struct sockaddr *)&addr6, sizeof(addr6)) != 0) {
            syslog(LOG_WARNING, "bind IPv6 listener failed: %s", strerror(errno));
            close(fd);
            return -1;
        }
    }

    if (listen(fd, SOMAXCONN) != 0) {
        syslog(LOG_WARNING, "listen failed: %s", strerror(errno));
        close(fd);
        return -1;
    }

    return fd;
}

static void close_listeners(struct proxy_listener *listeners, size_t count) {
    for (size_t i = 0; i < count; i++) {
        if (listeners[i].fd >= 0) {
            close(listeners[i].fd);
            listeners[i].fd = -1;
        }
    }
}

static void close_all_connections(struct proxy_context *ctx) {
    struct proxy_connection *conn = ctx->connections;
    while (conn != NULL) {
        struct proxy_connection *next = conn->next;
        connection_schedule_close(conn);
        conn = next;
    }
    free_closed_connections(ctx);
}

static struct proxy_connection *create_connection(struct proxy_context *ctx, int client_fd, int target_fd, int family,
                                                  bool target_in_progress) {
    struct proxy_connection *conn = malloc(sizeof(*conn));
    if (conn == NULL) {
        close(client_fd);
        close(target_fd);
        proxy_release_connection();
        return NULL;
    }

    conn->ctx = ctx;
    conn->next = NULL;
    conn->close_next = NULL;
    conn->client_fd = client_fd;
    conn->target_fd = target_fd;
    conn->family = family;
    conn->target_connected = !target_in_progress;
    conn->client_eof = false;
    conn->target_eof = false;
    conn->target_write_shutdown = false;
    conn->client_write_shutdown = false;
    conn->rewrite_disabled = false;
    conn->closing = false;
    conn->splice_pipe[0] = -1;
    conn->splice_pipe[1] = -1;
    conn->splice_pending = 0;
    conn->splice_enabled = create_splice_pipe(conn->splice_pipe) == 0;
    if (!conn->splice_enabled) {
        syslog(LOG_WARNING, "splice pipe unavailable, falling back to buffered proxy response forwarding: %s",
               strerror(errno));
    }
    memset(&conn->session, 0, sizeof(conn->session));
    conn->client_to_target.off = 0;
    conn->client_to_target.len = 0;
    conn->target_to_client.off = 0;
    conn->target_to_client.len = 0;
    conn->client_ref.type = EPOLL_REF_CONNECTION;
    conn->client_ref.connection.conn = conn;
    conn->client_ref.connection.side = PROXY_SIDE_CLIENT;
    conn->target_ref.type = EPOLL_REF_CONNECTION;
    conn->target_ref.connection.conn = conn;
    conn->target_ref.connection.side = PROXY_SIDE_TARGET;
    conn->client_armed = PROXY_EVENTS_UNSET;
    conn->target_armed = PROXY_EVENTS_UNSET;
    http_parser_init_session(&conn->session);
    connection_add(ctx, conn);

    const uint32_t target_initial = target_in_progress ? EPOLLOUT : EPOLLIN;
    if (epoll_set(ctx->epoll_fd, EPOLL_CTL_ADD, target_fd, &conn->target_ref, target_initial) != 0) {
        syslog(LOG_WARNING, "epoll target add failed: %s", strerror(errno));
        connection_schedule_close(conn);
        return NULL;
    }
    conn->target_armed = target_initial;

    if (!target_in_progress) {
        if (epoll_set(ctx->epoll_fd, EPOLL_CTL_ADD, client_fd, &conn->client_ref, EPOLLIN) != 0) {
            syslog(LOG_WARNING, "epoll client add failed: %s", strerror(errno));
            connection_schedule_close(conn);
            return NULL;
        }
        conn->client_armed = EPOLLIN;
    }

    connection_update_events(conn);
    return conn;
}

static void accept_listener_connections(struct proxy_context *ctx, const struct proxy_listener *listener,
                                        enum ua2f_mode mode, uint16_t listen_port) {
    for (;;) {
        const int client_fd = accept(listener->fd, NULL, NULL);
        if (client_fd < 0) {
            if (errno == EINTR) {
                continue;
            }
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                return;
            }
            syslog(LOG_WARNING, "accept failed: %s", strerror(errno));
            return;
        }

        if (!proxy_try_acquire_connection()) {
            syslog(LOG_WARNING, "Too many active proxy connections, rejecting client");
            close(client_fd);
            continue;
        }

        if (set_nonblocking(client_fd) != 0) {
            syslog(LOG_WARNING, "set client nonblocking failed: %s", strerror(errno));
            close(client_fd);
            proxy_release_connection();
            continue;
        }

        set_tcp_nodelay(client_fd);

        struct sockaddr_storage dst;
        socklen_t dst_len = sizeof(dst);
        bool got_dst = false;
        if (mode == UA2F_MODE_REDIRECT) {
            got_dst = get_redirect_original_dst(client_fd, listener->family, &dst, &dst_len);
        } else {
            got_dst = get_tproxy_original_dst(client_fd, &dst, &dst_len);
        }
        if (!got_dst) {
            close(client_fd);
            proxy_release_connection();
            continue;
        }

        if (should_drop_proxy_loop(client_fd, mode, &dst, listen_port)) {
            char dst_buf[128];
            format_sockaddr(&dst, dst_buf, sizeof(dst_buf));
            syslog(LOG_WARNING, "dropping transparent proxy loop to %s", dst_buf);
            close(client_fd);
            proxy_release_connection();
            continue;
        }

        if (dst.ss_family == AF_INET) {
            count_ipv4_packet();
        } else if (dst.ss_family == AF_INET6) {
            count_ipv6_packet();
        }

        bool target_in_progress = false;
        const int target_fd = connect_target(&dst, dst_len, &target_in_progress);
        if (target_fd < 0) {
            close(client_fd);
            proxy_release_connection();
            continue;
        }

        if (create_connection(ctx, client_fd, target_fd, listener->family, target_in_progress) == NULL) {
            free_closed_connections(ctx);
        }
    }
}

static int run_proxy_worker(enum ua2f_mode mode, uint16_t listen_port, volatile sig_atomic_t *should_exit,
                            int worker_id, int worker_count) {
    struct proxy_context ctx;
    memset(&ctx, 0, sizeof(ctx));
    ctx.epoll_fd = epoll_create1(EPOLL_CLOEXEC);
    if (ctx.epoll_fd < 0) {
        syslog(LOG_ERR, "epoll_create1 failed: %s", strerror(errno));
        return -1;
    }

    struct proxy_listener listeners[2] = {
        {.fd = -1, .family = AF_INET},
        {.fd = -1, .family = AF_INET6},
    };
    size_t listener_count = 0;

    const int v4 = create_listener(AF_INET, mode, listen_port);
    if (v4 >= 0) {
        listeners[listener_count] = (struct proxy_listener){.fd = v4, .family = AF_INET};
        listeners[listener_count].ref.type = EPOLL_REF_LISTENER;
        listeners[listener_count].ref.listener = &listeners[listener_count];
        listener_count++;
    }

    const int v6 = create_listener(AF_INET6, mode, listen_port);
    if (v6 >= 0) {
        listeners[listener_count] = (struct proxy_listener){.fd = v6, .family = AF_INET6};
        listeners[listener_count].ref.type = EPOLL_REF_LISTENER;
        listeners[listener_count].ref.listener = &listeners[listener_count];
        listener_count++;
    }

    if (listener_count == 0) {
        syslog(LOG_ERR, "Failed to start %s proxy listeners on port %u for worker %d", ua2f_mode_name(mode),
               (unsigned)listen_port, worker_id);
        close(ctx.epoll_fd);
        return -1;
    }

    for (size_t i = 0; i < listener_count; i++) {
        if (epoll_set(ctx.epoll_fd, EPOLL_CTL_ADD, listeners[i].fd, &listeners[i].ref, EPOLLIN) != 0) {
            syslog(LOG_ERR, "epoll listener add failed: %s", strerror(errno));
            close_listeners(listeners, listener_count);
            close(ctx.epoll_fd);
            return -1;
        }
    }

    if (worker_id == 0) {
        syslog(LOG_INFO, "UA2F %s mode listening on port %u with %d epoll worker(s)", ua2f_mode_name(mode),
               (unsigned)listen_port, worker_count);
    }

    while (!*should_exit) {
        struct epoll_event events[PROXY_MAX_EVENTS];
        const int ready = epoll_wait(ctx.epoll_fd, events, PROXY_MAX_EVENTS, 1000);
        if (ready < 0) {
            if (errno == EINTR) {
                continue;
            }
            syslog(LOG_ERR, "epoll_wait failed: %s", strerror(errno));
            close_all_connections(&ctx);
            close_listeners(listeners, listener_count);
            close(ctx.epoll_fd);
            return -1;
        }

        for (int i = 0; i < ready; i++) {
            struct epoll_ref *ref = (struct epoll_ref *)events[i].data.ptr;
            if (ref->type == EPOLL_REF_LISTENER) {
                accept_listener_connections(&ctx, ref->listener, mode, listen_port);
            } else if (ref->type == EPOLL_REF_CONNECTION) {
                handle_connection_event(ref, events[i].events);
            }
        }
        free_closed_connections(&ctx);
    }

    close_all_connections(&ctx);
    close_listeners(listeners, listener_count);
    close(ctx.epoll_fd);
    return 0;
}

static int proxy_worker_count(void) {
    const char *env_workers = getenv("UA2F_PROXY_WORKERS");
    if (env_workers != NULL && env_workers[0] != '\0') {
        char *end = NULL;
        errno = 0;
        const long requested = strtol(env_workers, &end, 10);
        if (errno == 0 && end != env_workers && *end == '\0' && requested > 0) {
            if (requested > PROXY_MAX_WORKERS) {
                syslog(LOG_WARNING, "UA2F_PROXY_WORKERS=%ld exceeds max %d, clamping", requested, PROXY_MAX_WORKERS);
                return PROXY_MAX_WORKERS;
            }
            return (int)requested;
        }
        syslog(LOG_WARNING, "Invalid UA2F_PROXY_WORKERS value: %s", env_workers);
    }

#ifdef UA2F_ENABLE_UCI
    if (config.proxy_workers > 0) {
        return config.proxy_workers;
    }
#endif

    const long cpu_count = sysconf(_SC_NPROCESSORS_ONLN);
    if (cpu_count <= 1) {
        return 1;
    }
    if (cpu_count > PROXY_DEFAULT_WORKERS) {
        return PROXY_DEFAULT_WORKERS;
    }
    return (int)cpu_count;
}

static void *proxy_worker_thread(void *arg) {
    struct proxy_worker_args *worker = (struct proxy_worker_args *)arg;
    worker->result =
        run_proxy_worker(worker->mode, worker->listen_port, worker->should_exit, worker->worker_id, worker->worker_count);
    if (worker->result != 0) {
        *worker->should_exit = 1;
    }
    return NULL;
}

int run_proxy(enum ua2f_mode mode, uint16_t listen_port, volatile sig_atomic_t *should_exit) {
    const int worker_count = proxy_worker_count();
    if (worker_count == 1) {
        return run_proxy_worker(mode, listen_port, should_exit, 0, 1);
    }

    pthread_t threads[PROXY_MAX_WORKERS];
    struct proxy_worker_args args[PROXY_MAX_WORKERS];
    int started = 0;
    for (int i = 0; i < worker_count; i++) {
        args[i] = (struct proxy_worker_args){
            .mode = mode,
            .listen_port = listen_port,
            .should_exit = should_exit,
            .worker_id = i,
            .worker_count = worker_count,
            .result = 0,
        };
        if (pthread_create(&threads[i], NULL, proxy_worker_thread, &args[i]) != 0) {
            syslog(LOG_ERR, "Failed to start proxy worker %d: %s", i, strerror(errno));
            *should_exit = 1;
            break;
        }
        started++;
    }

    int result = started == worker_count ? 0 : -1;
    for (int i = 0; i < started; i++) {
        pthread_join(threads[i], NULL);
        if (args[i].result != 0) {
            result = -1;
        }
    }
    return result;
}

#undef PROXY_MAX_WORKERS
#undef PROXY_DEFAULT_WORKERS
#undef PROXY_MAX_EVENTS
#undef PROXY_MAX_CONNECTIONS
#undef PROXY_SPLICE_SIZE
#undef PROXY_BUFFER_SIZE
