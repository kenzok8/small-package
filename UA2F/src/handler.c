#include <arpa/inet.h>
#include "handler.h"
#include "cache.h"
#include "util.h"
#include "statistics.h"
#include "custom.h"

#ifdef UA2F_ENABLE_UCI
#include "config.h"
#endif

#include <libnetfilter_queue/pktbuff.h>
#include <libnetfilter_queue/libnetfilter_queue_tcp.h>
#include <libnetfilter_queue/libnetfilter_queue_ipv4.h>
#include <libnetfilter_queue/libnetfilter_queue_ipv6.h>

#define MAX_USER_AGENT_LENGTH (0xffff + (MNL_SOCKET_BUFFER_SIZE / 2))
static char *replacement_user_agent_string = NULL;

#define USER_AGENT_MATCH "\r\nUser-Agent:"
#define USER_AGENT_MATCH_LENGTH 13

#define CONNMARK_ESTIMATE_LOWER 16
#define CONNMARK_ESTIMATE_UPPER 32
#define CONNMARK_ESTIMATE_VERDICT 33

#define CONNMARK_NOT_HTTP 43
#define CONNMARK_HTTP 44

void init_handler() {
    replacement_user_agent_string = malloc(MAX_USER_AGENT_LENGTH);

    bool ua_set = false;

#ifdef UA2F_ENABLE_UCI
    if (config.use_custom_ua) {
        memset(replacement_user_agent_string, ' ', MAX_USER_AGENT_LENGTH);
        strncpy(replacement_user_agent_string, config.custom_ua, strlen(config.custom_ua));
        syslog(LOG_INFO, "Using config user agent string: %s", replacement_user_agent_string);
        ua_set = true;
    }
#endif

#ifdef UA2F_CUSTOM_UA
    memset(replacement_user_agent_string, ' ', MAX_USER_AGENT_LENGTH);
    strncpy(replacement_user_agent_string, UA2F_CUSTOM_UA, strlen(UA2F_CUSTOM_UA));
    syslog(LOG_INFO, "Using embed user agent string: %s", replacement_user_agent_string);
    ua_set = true;
#endif

    if (!ua_set) {
        memset(replacement_user_agent_string, 'F', MAX_USER_AGENT_LENGTH);
        syslog(LOG_INFO, "Custom user agent string not set, using default F-string.");
    }

    syslog(LOG_INFO, "Handler initialized.");
}

// should free the ret value
static char *ip_to_str(const ip_address_t *ip, const uint16_t port, const int ip_version) {
    ASSERT(ip_version == IPV4 || ip_version == IPV6);
    char *ip_buf = malloc(MAX_ADDR_PORT_LENGTH);
    memset(ip_buf, 0, MAX_ADDR_PORT_LENGTH);
    const char *retval = NULL;

    if (ip_version == IPV4) {
        retval = inet_ntop(AF_INET, &ip->in4, ip_buf, INET_ADDRSTRLEN);
    } else {
        retval = inet_ntop(AF_INET6, &ip->in6, ip_buf, INET6_ADDRSTRLEN);
    }
    ASSERT(retval != NULL);

    char port_buf[7];
    sprintf(port_buf, ":%d", port);
    strcat(ip_buf, port_buf);

    return ip_buf;
}

struct mark_op {
    bool should_set;
    uint32_t mark;
};

static void send_verdict(
        const struct nf_queue *queue,
        const struct nf_packet *pkt,
        const struct mark_op mark,
        struct pkt_buff *mangled_pkt_buff) {
    struct nlmsghdr *nlh = nfqueue_put_header(pkt->queue_num, NFQNL_MSG_VERDICT);
    if (nlh == NULL) {
        syslog(LOG_ERR, "failed to put nfqueue header");
        goto end;
    }
    nfq_nlmsg_verdict_put(nlh, pkt->packet_id, NF_ACCEPT);

    if (mark.should_set) {
        struct nlattr *nest = mnl_attr_nest_start_check(nlh, SEND_BUF_LEN, NFQA_CT);
        if (nest == NULL) {
            syslog(LOG_ERR, "failed to put nfqueue attr");
            goto end;
        }
        if (!mnl_attr_put_u32_check(nlh, SEND_BUF_LEN, CTA_MARK, htonl(mark.mark))) {
            syslog(LOG_ERR, "failed to put nfqueue attr");
            goto end;
        }
        mnl_attr_nest_end(nlh, nest);
    }

    if (mangled_pkt_buff != NULL) {
        nfq_nlmsg_verdict_put_pkt(nlh, pktb_data(mangled_pkt_buff), pktb_len(mangled_pkt_buff));
    }

    const __auto_type ret = mnl_socket_sendto(queue->nl_socket, nlh, nlh->nlmsg_len);
    if (ret == -1) {
        syslog(LOG_ERR, "failed to send verdict: %s", strerror(errno));
    }

    end:
    if (nlh != NULL) {
        free(nlh);
    }
}

static bool conntrack_info_available = true;
static bool cache_initialized = false;

static void add_to_cache(const struct nf_packet *pkt) {
    char *ip_str = ip_to_str(&pkt->orig.dst, pkt->orig.dst_port, pkt->orig.ip_version);
    cache_add(ip_str);
    free(ip_str);
}

static struct mark_op get_next_mark(const struct nf_packet *pkt, const bool has_ua) {
    if (!conntrack_info_available) {
        return (struct mark_op) {false, 0};
    }

    // I didn't think this will happen, but just in case
    // firewall should already have a rule to return all marked with CONNMARK_NOT_HTTP packets
    if (pkt->conn_mark == CONNMARK_NOT_HTTP) {
        syslog(LOG_WARNING, "Packet has already been marked as not http. Maybe firewall rules are wrong?");
        return (struct mark_op) {false, 0};
    }

    if (pkt->conn_mark == CONNMARK_HTTP) {
        return (struct mark_op) {false, 0};
    }

    if (has_ua) {
        return (struct mark_op) {true, CONNMARK_HTTP};
    }

    if (!pkt->has_connmark || pkt->conn_mark == 0) {
        return (struct mark_op) {true, CONNMARK_ESTIMATE_LOWER};
    }

    if (pkt->conn_mark == CONNMARK_ESTIMATE_VERDICT) {
        add_to_cache(pkt);
        return (struct mark_op) {true, CONNMARK_NOT_HTTP};
    }

    if (pkt->conn_mark >= CONNMARK_ESTIMATE_LOWER && pkt->conn_mark <= CONNMARK_ESTIMATE_UPPER) {
        return (struct mark_op) {true, pkt->conn_mark + 1};
    }

    syslog(LOG_WARNING, "Unexpected connmark value: %d, Maybe other program has changed connmark?", pkt->conn_mark);
    return (struct mark_op) {true, pkt->conn_mark + 1};
}

bool should_ignore(const struct nf_packet *pkt) {
    bool retval = false;

    char *ip_str = ip_to_str(&pkt->orig.dst, pkt->orig.dst_port, pkt->orig.ip_version);
    retval = cache_contains(ip_str);
    free(ip_str);

    return retval;
}

void handle_packet(const struct nf_queue *queue, const struct nf_packet *pkt) {
    if (conntrack_info_available) {
        if (!pkt->has_conntrack) {
            conntrack_info_available = false;
            syslog(LOG_WARNING, "Packet has no conntrack. Switching to no cache mode.");
            syslog(LOG_WARNING, "Note that this may lead to performance degradation. Especially on low-end routers.");
        } else {
            if (!cache_initialized) {
                init_not_http_cache();
                cache_initialized = true;
            }
        }
    }

    struct pkt_buff *pkt_buff = NULL;
    if (conntrack_info_available && should_ignore(pkt)) {
        send_verdict(queue, pkt, (struct mark_op) {true, CONNMARK_NOT_HTTP}, NULL);
        goto end;
    }

    pkt_buff = pktb_alloc(AF_INET, pkt->payload, pkt->payload_len, 0);

    ASSERT(pkt_buff != NULL);

    int type;

    if (conntrack_info_available) {
        type = pkt->orig.ip_version;
    } else {
        const __auto_type ip_hdr = nfq_ip_get_hdr(pkt_buff);
        if (ip_hdr == NULL) {
            type = IPV6;
        } else {
            type = IPV4;
        }
    }

    if (type == IPV4) {
        count_ipv4_packet();
    } else {
        count_ipv6_packet();
    }

    if (type == IPV4) {
        const __auto_type ip_hdr = nfq_ip_get_hdr(pkt_buff);
        if (nfq_ip_set_transport_header(pkt_buff, ip_hdr) < 0) {
            syslog(LOG_ERR, "Failed to set ipv4 transport header");
            goto end;
        }
    } else {
        const __auto_type ip_hdr = nfq_ip6_get_hdr(pkt_buff);
        if (nfq_ip6_set_transport_header(pkt_buff, ip_hdr, IPPROTO_TCP) < 0) {
            syslog(LOG_ERR, "Failed to set ipv6 transport header");
            goto end;
        }
    }

    const __auto_type tcp_hdr = nfq_tcp_get_hdr(pkt_buff);
    if (tcp_hdr == NULL) {
        // This packet is not tcp, pass it
        send_verdict(queue, pkt, (struct mark_op) {false, 0}, NULL);
        syslog(LOG_WARNING, "Received non-tcp packet. You may set wrong firewall rules.");
        goto end;
    }

    const __auto_type tcp_payload = nfq_tcp_get_payload(tcp_hdr, pkt_buff);
    const __auto_type tcp_payload_len = nfq_tcp_get_payload_len(tcp_hdr, pkt_buff);

    if (tcp_payload == NULL || tcp_payload_len < USER_AGENT_MATCH_LENGTH) {
        send_verdict(queue, pkt, get_next_mark(pkt, false), NULL);
        goto end;
    }

    count_tcp_packet();

    // cannot find User-Agent: in this packet
    if (tcp_payload_len - 2 < USER_AGENT_MATCH_LENGTH) {
        send_verdict(queue, pkt, get_next_mark(pkt, false), NULL);
        goto end;
    }

// FIXME: can lead to false positive,
//        should also get CTA_COUNTERS_ORIG to check if this packet is a initial tcp packet

//    if (!is_http_protocol(tcp_payload, tcp_payload_len)) {
//        send_verdict(queue, pkt, get_next_mark(pkt, false), NULL);
//        goto end;
//    }
    count_http_packet();

    const void *search_start = tcp_payload;
    unsigned int search_length = tcp_payload_len;
    bool has_ua = false;

    while (true) {
        // minimal length of User-Agent: is 12
        if (search_length - 2 < USER_AGENT_MATCH_LENGTH) {
            break;
        }

        char *ua_pos = memncasemem(search_start, search_length, USER_AGENT_MATCH, USER_AGENT_MATCH_LENGTH);
        if (ua_pos == NULL) {
            break;
        }

        has_ua = true;

        void *ua_start = ua_pos + USER_AGENT_MATCH_LENGTH;

        // for non-standard user-agent like User-Agent:XXX with no space after colon
        if (*(char *) ua_start == ' ') {
            ua_start++;
        }

        const void *ua_end = memchr(ua_start, '\r', tcp_payload_len - (ua_start - tcp_payload));
        if (ua_end == NULL) {
            syslog(LOG_INFO, "User-Agent header is not terminated with \\r, not mangled.");
            send_verdict(queue, pkt, get_next_mark(pkt, true), NULL);
            goto end;
        }
        const unsigned int ua_len = ua_end - ua_start;
        const unsigned long ua_offset = ua_start - tcp_payload;

        // Looks it's impossible to mangle pocket failed, so we just drop it
        if (type == IPV4) {
            nfq_tcp_mangle_ipv4(pkt_buff, ua_offset, ua_len, replacement_user_agent_string, ua_len);
        } else {
            nfq_tcp_mangle_ipv6(pkt_buff, ua_offset, ua_len, replacement_user_agent_string, ua_len);
        }

        search_length = tcp_payload_len - (ua_end - tcp_payload);
        search_start = ua_end;
    }

    if (has_ua) {
        count_user_agent_packet();
    }

    send_verdict(queue, pkt, get_next_mark(pkt, has_ua), pkt_buff);

    end:
    free(pkt->payload);
    if (pkt_buff != NULL) {
        pktb_free(pkt_buff);
    }

    try_print_statistics();
}

#undef MAX_USER_AGENT_LENGTH
#undef USER_AGENT_MATCH_LENGTH

#undef CONNMARK_ESTIMATE_LOWER
#undef CONNMARK_ESTIMATE_UPPER
#undef CONNMARK_ESTIMATE_VERDICT

#undef CONNMARK_NOT_HTTP
#undef CONNMARK_HTTP
