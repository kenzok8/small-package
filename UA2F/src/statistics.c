#include "statistics.h"
#include <memory.h>
#include <stdatomic.h>
#include <stdio.h>
#include <syslog.h>
#include <time.h>

static atomic_llong user_agent_packet_count = 0;
static atomic_llong http_packet_count = 0;
static atomic_llong tcp_packet_count = 0;

static atomic_llong ipv4_packet_count = 0;
static atomic_llong ipv6_packet_count = 0;
static atomic_llong last_report_count = 1;

static time_t start_t;

void init_statistics() {
    start_t = time(NULL);
    syslog(LOG_INFO, "Statistics initialized.");
}

void count_user_agent_packet() { atomic_fetch_add_explicit(&user_agent_packet_count, 1, memory_order_relaxed); }

void count_tcp_packet() { atomic_fetch_add_explicit(&tcp_packet_count, 1, memory_order_relaxed); }

void count_http_packet() { atomic_fetch_add_explicit(&http_packet_count, 1, memory_order_relaxed); }

void count_ipv4_packet() { atomic_fetch_add_explicit(&ipv4_packet_count, 1, memory_order_relaxed); }

void count_ipv6_packet() { atomic_fetch_add_explicit(&ipv6_packet_count, 1, memory_order_relaxed); }

static void fill_time_string_to_buffer(const double sec, char *buffer, size_t buffer_len) {
    const int s = (int)sec;
    if (buffer_len == 0) {
        return;
    }
    memset(buffer, 0, buffer_len);
    if (s <= 60) {
        snprintf(buffer, buffer_len, "%d seconds", s);
    } else if (s <= 3600) {
        snprintf(buffer, buffer_len, "%d minutes and %d seconds", s / 60, s % 60);
    } else if (s <= 86400) {
        snprintf(buffer, buffer_len, "%d hours, %d minutes and %d seconds", s / 3600, s % 3600 / 60, s % 60);
    } else {
        snprintf(buffer, buffer_len, "%d days, %d hours, %d minutes and %d seconds", s / 86400, s % 86400 / 3600,
                 s % 3600 / 60, s % 60);
    }
}

char *fill_time_string(const double sec) {
    static _Thread_local char time_string_buffer[512];
    fill_time_string_to_buffer(sec, time_string_buffer, sizeof(time_string_buffer));
    return time_string_buffer;
}

void try_print_statistics() {
    const long long ua_count = atomic_load_explicit(&user_agent_packet_count, memory_order_relaxed);
    long long last_count = atomic_load_explicit(&last_report_count, memory_order_relaxed);
    if (ua_count / last_count == 2 || ua_count - last_count >= 8192) {
        if (!atomic_compare_exchange_strong_explicit(&last_report_count, &last_count, ua_count, memory_order_relaxed,
                                                     memory_order_relaxed)) {
            return;
        }
        const time_t current_t = time(NULL);
        char elapsed[512];
        fill_time_string_to_buffer(difftime(current_t, start_t), elapsed, sizeof(elapsed));
        syslog(LOG_INFO, "UA2F has handled %lld ua http, %lld http, %lld tcp. %lld ipv4, %lld ipv6 packets in %s.",
               ua_count, atomic_load_explicit(&http_packet_count, memory_order_relaxed),
               atomic_load_explicit(&tcp_packet_count, memory_order_relaxed),
               atomic_load_explicit(&ipv4_packet_count, memory_order_relaxed),
               atomic_load_explicit(&ipv6_packet_count, memory_order_relaxed),
               elapsed);
    }
}
