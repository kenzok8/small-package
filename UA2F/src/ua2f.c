#include "assert.h"
#include "cli.h"
#include "handler.h"
#include "statistics.h"
#include "util.h"
#include "backtrace.h"
#ifdef UA2F_ENABLE_UCI
#include "config.h"
#endif
#include "third/nfqueue-mnl/nfqueue-mnl.h"

#include <signal.h>
#include <stdlib.h>
#include <syslog.h>
#include <stdbool.h>

#pragma clang diagnostic push
#pragma ide diagnostic ignored "EndlessLoop"

volatile int should_exit = false;

void signal_handler(int sig) {
    syslog(LOG_INFO, "Received signal %d, preparing to exit...", sig);
    should_exit = true;
}

int parse_packet(const struct nf_queue *queue, struct nf_buffer *buf) {
    struct nf_packet packet[1] = {0};

    while (!should_exit) {
        const __auto_type status = nfqueue_next(buf, packet);
        if (status == IO_READY) {
            handle_packet(queue, packet);
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
    nfqueue_close(queue);

    syslog(LOG_INFO, "Retry without conntrack");
    const __auto_type ret = nfqueue_open(queue, QUEUE_NUM, 0, true);
    if (!ret) {
        syslog(LOG_ERR, "Failed to open nfqueue with conntrack disabled");
        return false;
    }
    return true;
}

void main_loop(struct nf_queue *queue) {
    struct nf_buffer buf[1] = {0};
    bool retried = false;

    while (!should_exit) {
        if (read_buffer(queue, buf) == IO_ERROR) {
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

    require_root();

    init_statistics();
    init_handler();

    UA2F_INIT_BACKTRACE();

    struct nf_queue queue[1] = {0};

    const __auto_type ret = nfqueue_open(queue, QUEUE_NUM, 0, false);
    if (!ret) {
        syslog(LOG_ERR, "Failed to open nfqueue");
        return EXIT_FAILURE;
    }
    assert(queue->queue_num == QUEUE_NUM);
    assert(queue->nl_socket != NULL);

    main_loop(queue);

    nfqueue_close(queue);

    syslog(LOG_INFO, "UA2F exiting gracefully");

    return EXIT_SUCCESS;
}

#pragma clang diagnostic pop