//
//  netutils.h
//  DaoNet
//
//  Created by realityone on 15/9/27.
//  Copyright © 2015年 realityone. All rights reserved.
//

#ifndef netutils_h
#define netutils_h

#include <stdio.h>
#include <sys/types.h>
#include <netdb.h>
#include <unistd.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <netinet/in.h>

int udp_init(const char *target, int port, struct sockaddr_in *out_s_addr);
void udp_close(int sockfd);

int udp_set_timeout(int sockfd, struct timeval timeout);
size_t udp_sendto(int sockfd, struct sockaddr_in *s_addr, u_char *send_data, size_t length);
size_t udp_rcvfrom(int sockfd, u_char *rcv_buffer, size_t buffer_size);

#endif /* netutils_h */
