#include <memory.h>
#include <stdio.h>
#include <time.h>
#include <syslog.h>
#include "statistics.h"

static long long user_agent_packet_count = 0;
static long long tcp_packet_count = 0;
static long long ipv4_packet_count = 0;
static long long ipv6_packet_count = 0;
static long long last_report_count = 4;

static time_t start_t;

void init_statistics() {
    start_t = time(NULL);
    syslog(LOG_INFO, "Statistics initialized.");
}

void count_user_agent_packet() {
    user_agent_packet_count++;
}

void count_tcp_packet() {
    tcp_packet_count++;
}

void count_ipv4_packet() {
    ipv4_packet_count++;
}

void count_ipv6_packet() {
    ipv6_packet_count++;
}

static char TimeStringBuffer[60];

char *fill_time_string(double sec) {
    int s = (int) sec;
    memset(TimeStringBuffer, 0, sizeof(TimeStringBuffer));
    if (s <= 60) {
        sprintf(TimeStringBuffer, "%d seconds", s);
    } else if (s <= 3600) {
        sprintf(TimeStringBuffer, "%d minutes and %d seconds", s / 60, s % 60);
    } else if (s <= 86400) {
        sprintf(TimeStringBuffer, "%d hours, %d minutes and %d seconds", s / 3600, s % 3600 / 60, s % 60);
    } else {
        sprintf(TimeStringBuffer, "%d days, %d hours, %d minutes and %d seconds", s / 86400, s % 86400 / 3600,
                s % 3600 / 60,
                s % 60);
    }
    return TimeStringBuffer;
}

void try_print_statistics() {
    if (user_agent_packet_count / last_report_count == 2 || user_agent_packet_count - last_report_count >= 16384) {
        last_report_count = user_agent_packet_count;
        time_t current_t = time(NULL);
        syslog(
                LOG_INFO,
                "UA2F has handled %lld ua http, %lld tcp. %lld ipv4, %lld ipv6 packets in %s.",
                user_agent_packet_count,
                tcp_packet_count,
                ipv4_packet_count,
                ipv6_packet_count,
                fill_time_string(difftime(current_t, start_t))
        );
    }
}


