#include "assert.h"
#include "backtrace.h"
#include "cli.h"
#include "handler.h"
#include "http_session.h"
#include "mode.h"
#include "proxy.h"
#include "session_cleaner.h"
#include "statistics.h"
#include "util.h"
#ifdef UA2F_HAS_CONNTRACK_LISTENER
#include "conntrack_listener.h"
#endif
#ifdef UA2F_ENABLE_UCI
#include "config.h"
#endif
#include "third/nfqueue-mnl/nfqueue-mnl.h"

#include <errno.h>
#include <pthread.h>
#include <signal.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

#pragma clang diagnostic push
#pragma ide diagnostic ignored "EndlessLoop"

#define UA2F_MAX_NFQUEUE_WORKERS 16

volatile sig_atomic_t should_exit = 0;

struct nfqueue_worker {
    struct nf_queue queue;
    pthread_t thread;
    bool opened;
};

void signal_handler(int sig) {
    (void)sig;
    should_exit = 1;
}

static int nfqueue_worker_count(void) {
    const char *value = getenv("UA2F_NFQUEUE_WORKERS");
    if (value == NULL || value[0] == '\0') {
#ifdef UA2F_ENABLE_UCI
        return config.nfqueue_workers;
#else
        return 1;
#endif
    }

    errno = 0;
    char *end = NULL;
    const long workers = strtol(value, &end, 10);
    if (errno != 0 || end == value || *end != '\0' || workers < 1) {
        syslog(LOG_WARNING, "Invalid UA2F_NFQUEUE_WORKERS=%s; using 1", value);
        return 1;
    }
    if (workers > UA2F_MAX_NFQUEUE_WORKERS) {
        syslog(LOG_WARNING,
               "UA2F_NFQUEUE_WORKERS=%ld exceeds maximum %d; using %d",
               workers,
               UA2F_MAX_NFQUEUE_WORKERS,
               UA2F_MAX_NFQUEUE_WORKERS);
        return UA2F_MAX_NFQUEUE_WORKERS;
    }

    return (int)workers;
}

int parse_packet(const struct nf_queue *queue, struct nf_buffer *buf) {
    struct nf_packet packet[1] = {0};

    while (!should_exit) {
        const __auto_type status = nfqueue_next(buf, packet);
        if (status == IO_READY) {
            handle_packet(&nfqueue_packet_io, (void *)queue, packet);
        } else {
            return status;
        }
    }

    return IO_ERROR;
}

int read_buffer(struct nf_queue *queue, struct nf_buffer *buf) {
    // Use timeout to allow periodic checking of should_exit flag during signal handling
    const __auto_type buf_status = nfqueue_receive(queue, buf, 1000);
    if (buf_status == IO_READY) {
        return parse_packet(queue, buf);
    }
    return buf_status;
}

bool retry_without_conntrack(struct nf_queue *queue) {
    const int queue_num = queue->queue_num;
    nfqueue_close(queue);

    syslog(LOG_INFO, "Retry queue %d without conntrack", queue_num);
    const __auto_type ret = nfqueue_open(queue, queue_num, 0, true);
    if (!ret) {
        syslog(LOG_ERR, "Failed to open nfqueue %d with conntrack disabled", queue_num);
        return false;
    }
    return true;
}

void main_loop(struct nf_queue *queue) {
    struct nf_buffer buf[1] = {0};
    bool retried = false;

    while (!should_exit) {
        if (read_buffer(queue, buf) == IO_ERROR) {
            if (should_exit) {
                break;
            }
            if (!retried) {
                retried = true;
                if (!retry_without_conntrack(queue)) {
                    break;
                }
            } else {
                should_exit = true;
                break;
            }
        }
    }

    free(buf->data);
}

static void *nfqueue_worker_main(void *arg) {
    struct nfqueue_worker *worker = arg;
    main_loop(&worker->queue);
    return NULL;
}

static void close_nfqueue_workers(struct nfqueue_worker *workers, int worker_count) {
    for (int i = 0; i < worker_count; i++) {
        if (workers[i].opened && workers[i].queue.nl_socket != NULL) {
            nfqueue_close(&workers[i].queue);
            workers[i].opened = false;
        }
    }
}

static bool open_nfqueue_workers(struct nfqueue_worker *workers, int worker_count) {
    for (int i = 0; i < worker_count; i++) {
        const int queue_num = QUEUE_NUM + i;
        const __auto_type ret = nfqueue_open(&workers[i].queue, queue_num, 0, false);
        if (!ret) {
            syslog(LOG_ERR, "Failed to open nfqueue %d", queue_num);
            close_nfqueue_workers(workers, worker_count);
            return false;
        }
        workers[i].opened = true;
        assert(workers[i].queue.queue_num == queue_num);
        assert(workers[i].queue.nl_socket != NULL);
    }

    return true;
}

static int run_nfqueue_workers(int worker_count) {
    struct nfqueue_worker *workers = calloc((size_t)worker_count, sizeof(*workers));
    if (workers == NULL) {
        syslog(LOG_ERR, "Failed to allocate nfqueue workers");
        return EXIT_FAILURE;
    }

    if (!open_nfqueue_workers(workers, worker_count)) {
        free(workers);
        return EXIT_FAILURE;
    }

#ifdef UA2F_HAS_CONNTRACK_LISTENER
    init_conntrack_listener();
#endif

    if (worker_count == 1) {
        main_loop(&workers[0].queue);
    } else {
        int created = 0;
        for (; created < worker_count; created++) {
            const int ret = pthread_create(&workers[created].thread, NULL, nfqueue_worker_main, &workers[created]);
            if (ret != 0) {
                syslog(LOG_ERR, "Failed to create nfqueue worker thread: %s", strerror(ret));
                should_exit = 1;
                break;
            }
        }

        for (int i = 0; i < created; i++) {
            pthread_join(workers[i].thread, NULL);
        }

        if (created != worker_count) {
            close_nfqueue_workers(workers, worker_count);
            free(workers);
            return EXIT_FAILURE;
        }
    }

    close_nfqueue_workers(workers, worker_count);
    free(workers);
    return EXIT_SUCCESS;
}

int main(const int argc, char *argv[]) {
    openlog("UA2F", LOG_PID, LOG_SYSLOG);

    // Register signal handlers for graceful shutdown
    signal(SIGTERM, signal_handler);
    signal(SIGINT, signal_handler);

#ifdef UA2F_ENABLE_UCI
    load_config();
#else
    syslog(LOG_INFO, "uci support is disabled");
#endif

    try_print_info(argc, argv);

    enum ua2f_mode mode = UA2F_MODE_NFQUEUE;
    uint16_t listen_port = UA2F_DEFAULT_PROXY_PORT;
#ifdef UA2F_ENABLE_UCI
    mode = config.mode;
    listen_port = config.listen_port;
#endif
    if (cli_mode_set) {
        mode = cli_mode;
    }
    if (cli_listen_port_set) {
        listen_port = cli_listen_port;
    }

    require_root();

    init_statistics();
    init_handler();

#ifdef UA2F_ENABLE_UCI
    init_http_sessions(config.max_http_sessions);
    init_session_cleaner(config.session_ttl, 60);
#else
    init_http_sessions(UA2F_DEFAULT_MAX_HTTP_SESSIONS);
    init_session_cleaner(300, 60);
#endif

    UA2F_INIT_BACKTRACE();

    if (mode == UA2F_MODE_REDIRECT || mode == UA2F_MODE_TPROXY) {
        syslog(LOG_INFO, "Starting in %s mode on listen port %u", ua2f_mode_name(mode), (unsigned)listen_port);
        if (run_proxy(mode, listen_port, &should_exit) != 0) {
            return EXIT_FAILURE;
        }
        syslog(LOG_INFO, "UA2F exiting gracefully");
        return EXIT_SUCCESS;
    }

    const int worker_count = nfqueue_worker_count();
    if (worker_count == 1) {
        syslog(LOG_INFO, "Starting in NFQUEUE mode on queue %d", QUEUE_NUM);
    } else {
        syslog(LOG_INFO,
               "Starting in NFQUEUE mode on queues %d-%d with %d workers",
               QUEUE_NUM,
               QUEUE_NUM + worker_count - 1,
               worker_count);
    }

    const int result = run_nfqueue_workers(worker_count);
    syslog(LOG_INFO, "UA2F exiting gracefully");

    return result;
}

#pragma clang diagnostic pop
