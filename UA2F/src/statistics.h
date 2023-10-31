#ifndef UA2F_STATISTICS_H
#define UA2F_STATISTICS_H

void count_user_agent_packet();

void count_tcp_packet();

void count_ipv4_packet();

void count_ipv6_packet();

void count_http_packet();

void init_statistics();

void try_print_statistics();

#endif //UA2F_STATISTICS_H
