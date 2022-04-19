//
//  netutils.c
//  DaoNet
//
//  Created by realityone on 15/9/27.
//  Copyright © 2015年 realityone. All rights reserved.
//

#include "netutils.h"

int udp_init(const char *target, int port, struct sockaddr_in *out_s_addr) {
    out_s_addr->sin_family = AF_INET;
    out_s_addr->sin_addr.s_addr = inet_addr(target);
    out_s_addr->sin_port = htons(port);
    
    return socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
}

void udp_close(int sockfd) {
    close(sockfd);
}

int udp_set_timeout(int csockfd, struct timeval timeout) {
    return setsockopt(csockfd, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(struct timeval));
}

size_t udp_sendto(int sockfd, struct sockaddr_in *s_addr, u_char *send_data, size_t length) {
    return sendto(sockfd, send_data,
                  length, 0,
                  (struct sockaddr *)s_addr, sizeof(struct sockaddr));
}

size_t udp_rcvfrom(int sockfd, u_char *rcv_buffer, size_t buffer_size) {
    return recvfrom(sockfd, rcv_buffer,
                    buffer_size, 0, NULL, NULL);
}