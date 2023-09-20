/*
 *  nfqueue-mnl.h - Interface to netfilter (nfqueue and conntrack) using libmnl
 *  Copyright (c) 2019 Maciej Puzio
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program - see the file COPYING.
 *
 *  This file includes code from netfilter libnml example files,
 *  which had been placed in public domain by their author.
 */
#ifndef NFQUEUE_MNL_H
#define NFQUEUE_MNL_H

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedGlobalDeclarationInspection"

#include <stdio.h>      //fprintf
#include <stdlib.h>     //malloc, free
#include <stdbool.h>    //bool type
#include <sys/select.h> //pselect
#include <errno.h>      //errno, EINTR, ...
#include <netinet/in.h> //in_addr, in6_addr, ...
#include <time.h>       //timespec, clock_gettime
#include <string.h>     //memset, strerror
#include <libmnl/libmnl.h>

#include <linux/netfilter.h>                     //NF_ACCEPT and NF_DROP
#include <linux/netfilter/nfnetlink_queue.h>     //NFQA_* and NFQNL_*
#include <linux/netfilter/nfnetlink_conntrack.h> //CTA_*
#include <syslog.h>                              //LOG_*
#include <libnetfilter_queue/libnetfilter_queue.h>

/*
Kernel compatibility notes

Kernel 3.8 or later is required, as this code does not perform PF_BIND anf PF_UNBIND.
A bug in kernel causes it not to pass the timestamp attribute (always zero), depending on kernel version and NIC driver.
This is worked around by using our own timestamps.
*/

/*
Reasons for attributes packed and may_alias:
Attribute 'packed' is needed here to force the compiler to emit unaligned-access opcodes when accessing
objects of ip_address_t type. Such unaligned accesses happen because IP addresses are passed as Netlink
payloads that are not aligned to 16-byte boundaries. On x86_64 this means emiting movdqu and movups
instead of movdqa and movaps.
Attribute "may_alias" is used to prevent the compiler using strict aliasing optimizations for accesses
to ip_address_t. This is desirable because cross-type aliasing is what ip_address_t is designed for.
*/

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Enums and object definitions

// ip_version
enum {
    IPV4 = 4,
    IPV6 = 6
};

// I/O result
enum {
    IO_ERROR = -1,
    IO_NOTREADY = 0, // timeout or no more data
    IO_READY = 1     // data ready
};

typedef union __attribute__((packed, may_alias)) {
    uint8_t ip[16]; // alternative for __uint128_t
    uint32_t ip4;
    struct in_addr in4;
    struct in6_addr in6;
    struct {
        uint64_t hi;
        uint64_t lo;
    };
} ip_address_t;

struct ip_tuple {
    int ip_version;
    ip_address_t src;
    ip_address_t dst;
    uint16_t src_port;
    uint16_t dst_port;
};

// Netlink packet object
// This structure collects packet information passed by netfilter.

struct nf_packet {
    int queue_num;
    uint32_t packet_id;        // from NFQA_PACKET_HDR
    uint16_t hw_protocol;      // from NFQA_PACKET_HDR; see https://en.wikipedia.org/wiki/EtherType
    size_t payload_len;        // NFQA_PAYLOAD length
    void *payload;             // NFQA_PAYLOAD
    bool has_timestamp;        // true if netfilter provided a timestamp
    struct timeval timestamp;  // NFQA_TIMESTAMP (if has_timestamp) or zero
    struct timespec wall_time; // clock_gettime(CLOCK_REALTIME)
    struct timespec mono_time; // clock_gettime(CLOCK_MONOTONIC_RAW)
    bool has_conntrack;        // true if netfilter provided conntrack info (if not, the following fields are zero)
    bool has_connmark;         // true if CTA_MARK is present
    uint32_t conn_id;          // NFQA_CT > CTA_ID; see https://www.spinics.net/lists/netdev/msg443125.html and https://patchwork.kernel.org/patch/9820809/
    uint32_t conn_mark;        // NFQA_CT > CTA_MARK
    uint32_t conn_state;       // NFQA_CT_INFO (IP_CT_NEW/ESTABLISHED/RELATED/...)
    uint32_t conn_status;      // NDQA_CT > CTA_STATUS (IPS_SEEN_REPLY/CONFIRMED/...)
    struct ip_tuple orig;      // NFQA_CT > CTA_TUPLE_ORIG
    struct ip_tuple reply;     // NFQA_CT > CTA_TUPLE_REPLY
};

/* addr_tuple fields
    int               ip_version;     // IPV4 or IPV6
    ip_address_t      src;            // CTA_TUPLE_IP > CTA_IP_V?_SRC
    ip_address_t      dst;            // CTA_TUPLE_IP > CTA_IP_V?_DST
    uint16_t          src_port;       // CTA_TUPLE_PROTO > CTA_PROTO_SRC_PORT
    uint16_t          dst_port;       // CTA_TUPLE_PROTO > CTA_PROTO_DST_PORT
*/

struct nf_queue {
    int queue_num;
    struct mnl_socket *nl_socket;
};

struct nf_buffer {
    void *data;
    struct nlmsghdr *nlh;
    int len; // used part of data buffer
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Error handling and logging

#ifndef LOG
#define LOG(priority, fmt, ...) syslog(priority, fmt, ##__VA_ARGS__)
#endif

#ifndef DIE
#define DIE() exit(EXIT_FAILURE)
#endif

#define LOG_ONCE(priority, fmt, ...)             \
    do                                           \
    {                                            \
        static bool done = false;                \
        if (!done)                               \
        {                                        \
            LOG((priority), fmt, ##__VA_ARGS__); \
            done = true;                         \
        }                                        \
    } while (0)

#define LOG_SYSERR(fmt, ...) \
    LOG(LOG_ERR, fmt ": %s", ##__VA_ARGS__, strerror(errno))

#ifdef IS_DEV
#define DEBUG(fmt, ...) \
    LOG(LOG_DEBUG, fmt, ##__VA_ARGS__)
#else
#define DEBUG(fmt, ...)
#endif

#define ASSERT(condition)                                                                            \
    do                                                                                               \
    {                                                                                                \
        if (!(condition))                                                                            \
        {                                                                                            \
            LOG(LOG_CRIT, "Assert failed: %s [%s:%s:%d]", #condition, __func__, __FILE__, __LINE__); \
            DIE();                                                                                   \
        }                                                                                            \
    } while (0)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MNL integer attr functions redefinitions

/*
Reason:
libmnl contains functions mnl_attr_get_u[16|32] that may return unaligned 16-bit and 32-bit integers.
Below we redefine these functions with alignment-safe implementations.
mnl_attr_get_u8 is immune from aligment issues, by virtue of uint8_t requiring alignment 1.
mnl_attr_get_u64 is implemented by libmnl in an alignment-safe manner, similar to one that we use below.
*/

static uint16_t fixed_attr_get_u16(const struct nlattr *attr);

static uint32_t fixed_attr_get_u32(const struct nlattr *attr);

#define mnl_attr_get_u16(attr) fixed_attr_get_u16(attr)
#define mnl_attr_get_u32(attr) fixed_attr_get_u32(attr)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Sending Netlink commands

#define SEND_BUF_LEN MNL_SOCKET_BUFFER_SIZE
#define RECV_BUF_LEN (MNL_SOCKET_BUFFER_SIZE + 0xFFFF)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Public interface

/*
Example usage

    struct nf_buffer buf[1];
    memset(buf, 0, sizeof(struct nf_buffer));

    while (...)
    {
        if (nfqueue_receive(nfqueue, buf, TIMEOUT) == IO_READY)
        {
            struct nf_packet packet[1];
            while (nfqueue_next(buf, packet) == IO_READY)
            {
                handle_packet(packet);
                free(packet->payload);
            }
        }
    }
    free(buf->data);
*/

/*
Note about thread safety

Function nfqueue_open() is not thread safe, but after the queue is open, most operation on it are.
Assuming that receive, send and select operations on a netlink socket are thread-safe, nfqueue_receive() and
nfqueue_verdict() are thread-safe with respect to nf_queue argument. This means that nf_queue object can be
shared between threads. On the other hand, operations on nf_buffer are not thread-safe, and because of that
every thread calling nfqueue_receive() and nfqueue_next() should use its own nf_buffer. By splitting nf_buffer
from nf_queue we allow for multithreaded access to the netfilter queue.
Note that nfqueue_next() copies the payload from nf_buffer to packet object, thus nf_buffer can be reused in
nfqueue_receive() while packet object is being processed by another thread.
*/

// Return false on failure
// If queue_len is zero, use default value
bool nfqueue_open(struct nf_queue *q, int queue_num, uint32_t queue_len);

void nfqueue_close(struct nf_queue *q);

// Return false on failure
// connmark is uint64_t to allow full 32-bit unsigned integer and also -1 (meaning: don't set connmark)
bool nfqueue_verdict(struct nf_queue *q, uint32_t packet_id, int verdict, int64_t connmark);

// Return 1 on success, -1 on failure, 0 on timeout (if timeout_ms > 0) or data not ready
int nfqueue_receive(struct nf_queue *q, struct nf_buffer *buf, int64_t timeout_ms);

// Return 1 on success (result in packet), -1 on failure, 0 on no more data
int nfqueue_next(struct nf_buffer *buf, struct nf_packet *packet);

struct nlmsghdr *nfqueue_put_header(int queue_num, int msg_type);

#pragma clang diagnostic pop
#endif // NFQUEUE_MNL_H