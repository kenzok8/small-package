#include "handler.h"
#include "assert.h"
#include "cache.h"
#include "custom.h"
#include "http_parser_ua.h"
#include "http_session.h"
#include "statistics.h"
#include "util.h"

#ifdef UA2F_ENABLE_UCI
#include "config.h"
#endif

#include <arpa/inet.h>
#include <libnetfilter_queue/libnetfilter_queue_ipv4.h>
#include <libnetfilter_queue/libnetfilter_queue_ipv6.h>
#include <libnetfilter_queue/libnetfilter_queue_tcp.h>
#include <libnetfilter_queue/pktbuff.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <limits.h>
#include <netinet/in.h>
#include <netinet/ip6.h>
#include <netinet/tcp.h>
#include <stdlib.h>

static char *replacement_user_agent_string = NULL;
static bool replacement_user_agent_cleanup_registered = false;

static const struct mark_op MARK_NONE = {false, 0};
static const struct mark_op MARK_NOT_HTTP = {true, CONNMARK_NOT_HTTP};
static const struct mark_op MARK_HTTP = {true, CONNMARK_HTTP};

#ifndef UA2F_NO_CACHE
bool use_conntrack = true;
#else
bool use_conntrack = false;
#endif

static void destroy_handler(void) {
    free(replacement_user_agent_string);
    replacement_user_agent_string = NULL;
}

void init_handler() {
    init_not_http_cache(60);

    destroy_handler();
    replacement_user_agent_string = malloc(UA2F_MAX_USER_AGENT_LENGTH);
    assert(replacement_user_agent_string != NULL && "Failed to allocate user agent string");
    if (!replacement_user_agent_cleanup_registered) {
        atexit(destroy_handler);
        replacement_user_agent_cleanup_registered = true;
    }
    bool ua_set = false;

#ifdef UA2F_ENABLE_UCI
    if (config.use_custom_ua) {
        memset(replacement_user_agent_string, ' ', UA2F_MAX_USER_AGENT_LENGTH);
        size_t custom_ua_len = strlen(config.custom_ua);
        if (custom_ua_len > UA2F_MAX_USER_AGENT_LENGTH) {
            syslog(LOG_WARNING, "Config user agent string is too long, truncating to %zu bytes",
                   (size_t)UA2F_MAX_USER_AGENT_LENGTH);
            custom_ua_len = UA2F_MAX_USER_AGENT_LENGTH;
        }
        memcpy(replacement_user_agent_string, config.custom_ua, custom_ua_len);
        syslog(LOG_INFO, "Using config user agent string: %.*s", (int)custom_ua_len, replacement_user_agent_string);
        ua_set = true;
    }

    if (config.disable_connmark) {
        use_conntrack = false;
        syslog(LOG_INFO, "Conntrack cache disabled by config.");
    }
#endif

#ifdef UA2F_USE_CUSTOM_UA
    if (!ua_set) {
        memset(replacement_user_agent_string, ' ', UA2F_MAX_USER_AGENT_LENGTH);
        size_t custom_ua_len = strlen(UA2F_CUSTOM_UA);
        if (custom_ua_len > UA2F_MAX_USER_AGENT_LENGTH) {
            syslog(LOG_WARNING, "Embed user agent string is too long, truncating to %zu bytes",
                   (size_t)UA2F_MAX_USER_AGENT_LENGTH);
            custom_ua_len = UA2F_MAX_USER_AGENT_LENGTH;
        }
        memcpy(replacement_user_agent_string, UA2F_CUSTOM_UA, custom_ua_len);
        syslog(LOG_INFO, "Using embed user agent string: %.*s", (int)custom_ua_len, replacement_user_agent_string);
        ua_set = true;
    }
#endif

    if (!ua_set) {
        memset(replacement_user_agent_string, 'F', UA2F_MAX_USER_AGENT_LENGTH);
        syslog(LOG_INFO, "Custom user agent string not set, using default F-string.");
    }

    syslog(LOG_INFO, "Handler initialized.");
}

const char *get_replacement_user_agent_string() { return replacement_user_agent_string; }

size_t get_replacement_user_agent_string_length() { return UA2F_MAX_USER_AGENT_LENGTH; }

static const char *replacement_chunk(size_t replacement_offset, size_t ua_len, char **owned) {
    *owned = NULL;

    if (replacement_offset <= UA2F_MAX_USER_AGENT_LENGTH && ua_len <= UA2F_MAX_USER_AGENT_LENGTH - replacement_offset) {
        return replacement_user_agent_string + replacement_offset;
    }

    char *buf = malloc(ua_len);
    if (buf == NULL) {
        return NULL;
    }
    memset(buf, ' ', ua_len);

    if (replacement_offset < UA2F_MAX_USER_AGENT_LENGTH) {
        size_t available = UA2F_MAX_USER_AGENT_LENGTH - replacement_offset;
        if (available > ua_len) {
            available = ua_len;
        }
        memcpy(buf, replacement_user_agent_string + replacement_offset, available);
    }

    *owned = buf;
    return buf;
}

void add_to_cache(const struct nf_packet *pkt) {
    const struct addr_port target = {
        .addr = pkt->orig.dst,
        .port = pkt->orig.dst_port,
    };

    cache_add(target);
}

bool should_ignore(const struct nf_packet *pkt) {
    bool retval = false;
    struct addr_port target = {
        .addr = pkt->orig.dst,
        .port = pkt->orig.dst_port,
    };

    retval = cache_contains(target);

    return retval;
}

enum {
    IP_UNK = 0,
};

bool ipv4_set_transport_header(struct pkt_buff *pkt_buff) {
    struct iphdr *ip_hdr = nfq_ip_get_hdr(pkt_buff);
    if (ip_hdr == NULL) {
        syslog(LOG_ERR, "Failed to get ipv4 ip header");
        return false;
    }

    if (nfq_ip_set_transport_header(pkt_buff, ip_hdr) == -1) {
        syslog(LOG_ERR, "Failed to set ipv4 transport header");
        return false;
    }
    return true;
}

bool ipv6_set_transport_header(struct pkt_buff *pkt_buff) {
    struct ip6_hdr *ip_hdr = nfq_ip6_get_hdr(pkt_buff);
    if (ip_hdr == NULL) {
        syslog(LOG_ERR, "Failed to get ipv6 ip header");
        return false;
    }

    if (nfq_ip6_set_transport_header(pkt_buff, ip_hdr, IPPROTO_TCP) == 0) {
        syslog(LOG_ERR, "Failed to set ipv6 transport header");
        return false;
    }
    return true;
}

static size_t tcp_header_length(const struct tcphdr *tcp_hdr) {
    return (size_t)tcp_hdr->th_off * 4U;
}

static bool packet_has_tcp_payload_fast(const struct nf_packet *pkt, int type, bool *has_payload) {
    *has_payload = false;

    if (type == IPV4) {
        if (pkt->payload_len < sizeof(struct iphdr)) {
            return false;
        }

        const struct iphdr *ip_hdr = (const struct iphdr *)pkt->payload;
        if (ip_hdr->version != 4 || ip_hdr->protocol != IPPROTO_TCP) {
            return false;
        }

        const size_t ip_header_len = (size_t)ip_hdr->ihl * 4U;
        const size_t ip_total_len = (size_t)ntohs(ip_hdr->tot_len);
        const uint16_t fragment = ntohs(ip_hdr->frag_off);
        if (ip_header_len < sizeof(struct iphdr) || ip_total_len < ip_header_len ||
            ip_total_len > pkt->payload_len || (fragment & 0x3fffU) != 0) {
            return false;
        }
        if (ip_total_len < ip_header_len + sizeof(struct tcphdr)) {
            return false;
        }

        const struct tcphdr *tcp_hdr = (const struct tcphdr *)((const uint8_t *)pkt->payload + ip_header_len);
        const size_t tcp_header_len = tcp_header_length(tcp_hdr);
        if (tcp_header_len < sizeof(struct tcphdr) || ip_total_len < ip_header_len + tcp_header_len) {
            return false;
        }

        *has_payload = ip_total_len > ip_header_len + tcp_header_len;
        return true;
    }

    if (type == IPV6) {
        if (pkt->payload_len < sizeof(struct ip6_hdr)) {
            return false;
        }

        const struct ip6_hdr *ip_hdr = (const struct ip6_hdr *)pkt->payload;
        if ((ip_hdr->ip6_vfc >> 4) != 6 || ip_hdr->ip6_nxt != IPPROTO_TCP) {
            return false;
        }

        const size_t ip_total_len = sizeof(struct ip6_hdr) + (size_t)ntohs(ip_hdr->ip6_plen);
        if (ip_total_len < sizeof(struct ip6_hdr) || ip_total_len > pkt->payload_len ||
            ip_total_len < sizeof(struct ip6_hdr) + sizeof(struct tcphdr)) {
            return false;
        }

        const struct tcphdr *tcp_hdr = (const struct tcphdr *)((const uint8_t *)pkt->payload + sizeof(struct ip6_hdr));
        const size_t tcp_header_len = tcp_header_length(tcp_hdr);
        if (tcp_header_len < sizeof(struct tcphdr) || ip_total_len < sizeof(struct ip6_hdr) + tcp_header_len) {
            return false;
        }

        *has_payload = ip_total_len > sizeof(struct ip6_hdr) + tcp_header_len;
        return true;
    }

    return false;
}

int get_pkt_ip_version(const struct nf_packet *pkt) {
    if (pkt->has_conntrack) {
        return pkt->orig.ip_version;
    }

    switch (pkt->hw_protocol) {
    case ETH_P_IP:
        return IPV4;
    case ETH_P_IPV6:
        return IPV6;
    default:
        syslog(LOG_WARNING, "Received unknown ip packet %x.", pkt->hw_protocol);
        return IP_UNK;
    }
}

static void count_ip_packet(int type) {
    if (type == IPV4) {
        count_ipv4_packet();
    } else if (type == IPV6) {
        count_ipv6_packet();
    }
}

void handle_packet(const struct packet_io *io, void *io_ctx, const struct nf_packet *pkt) {
    assert(io != NULL && "Packet I/O cannot be NULL");
    assert(io->send_verdict != NULL && "send_verdict callback cannot be NULL");
    assert(pkt != NULL && "Packet cannot be NULL");
    assert(pkt->payload != NULL && "Packet payload cannot be NULL");
    assert(pkt->payload_len > 0 && "Packet payload length must be positive");
    struct pkt_buff *pkt_buff = NULL;
    bool ct_ok = use_conntrack && pkt->has_conntrack;
    bool verdict_sent = false;

#define SEND_VERDICT(verdict_, mark_, pkt_buff_)                                                                          \
    do {                                                                                                                  \
        io->send_verdict(io_ctx, pkt, (verdict_), (mark_), (pkt_buff_));                                                  \
        verdict_sent = true;                                                                                              \
    } while (0)

    // Level 1: cache check
    if (ct_ok && should_ignore(pkt)) {
        SEND_VERDICT(NF_ACCEPT, MARK_NOT_HTTP, NULL);
        goto end;
    }

    const int type = get_pkt_ip_version(pkt);
    if (type == IP_UNK) {
        syslog(LOG_WARNING, "Received unknown ip packet type %x. You may set wrong firewall rules.", pkt->hw_protocol);
        SEND_VERDICT(NF_ACCEPT, MARK_NONE, NULL);
        goto end;
    }

    bool has_tcp_payload = false;
    bool counted_ip_packet = false;
    if (packet_has_tcp_payload_fast(pkt, type, &has_tcp_payload)) {
        count_ip_packet(type);
        counted_ip_packet = true;
        if (!has_tcp_payload) {
            SEND_VERDICT(NF_ACCEPT, MARK_NONE, NULL);
            goto end;
        }
    }

    pkt_buff = pktb_alloc(type == IPV4 ? AF_INET : AF_INET6, pkt->payload, pkt->payload_len, 0);
    if (pkt_buff == NULL) {
        syslog(LOG_ERR, "Failed to allocate packet buffer");
        goto end;
    }

    if (type == IPV4) {
        if (!ipv4_set_transport_header(pkt_buff)) {
            syslog(LOG_ERR, "Failed to set ipv4 transport header");
            goto end;
        }
        if (!counted_ip_packet) {
            count_ipv4_packet();
        }
    } else if (type == IPV6) {
        if (!ipv6_set_transport_header(pkt_buff)) {
            syslog(LOG_ERR, "Failed to set ipv6 transport header");
            goto end;
        }
        if (!counted_ip_packet) {
            count_ipv6_packet();
        }
    } else {
        syslog(LOG_ERR, "Unknown ip version");
        goto end;
    }

    if (pktb_transport_header(pkt_buff) == NULL) {
        char msg[300];
        if (type == IPV4) {
            syslog(LOG_WARNING, "Failed to set ipv4 transport header.");
            const __auto_type ip_hdr = nfq_ip_get_hdr(pkt_buff);
            if (ip_hdr != NULL) {
                nfq_ip_snprintf(msg, sizeof(msg), ip_hdr);
            } else {
                syslog(LOG_WARNING, "Failed to get ipv4 ip header");
                goto end;
            }
        } else {
            syslog(LOG_WARNING, "Failed to set ipv6 transport header.");
            const __auto_type ip_hdr = nfq_ip6_get_hdr(pkt_buff);
            if (ip_hdr != NULL) {
                nfq_ip6_snprintf(msg, sizeof(msg), ip_hdr);
            } else {
                syslog(LOG_WARNING, "Failed to get ipv6 ip header");
                goto end;
            }
        }
        syslog(LOG_WARNING, "Header: %s", msg);
        goto end;
    }

    const __auto_type tcp_hdr = nfq_tcp_get_hdr(pkt_buff);
    if (tcp_hdr == NULL) {
        // This packet is not tcp, pass it
        syslog(LOG_WARNING, "No tcp header found");
        SEND_VERDICT(NF_ACCEPT, MARK_NONE, NULL);
        goto end;
    }

    const __auto_type tcp_payload = nfq_tcp_get_payload(tcp_hdr, pkt_buff);
    if (tcp_payload == NULL) {
        // Empty ACK or no payload — just accept, don't mark
        SEND_VERDICT(NF_ACCEPT, MARK_NONE, NULL);
        goto end;
    }

    const __auto_type tcp_payload_len = nfq_tcp_get_payload_len(tcp_hdr, pkt_buff);
    if (tcp_payload_len == 0) {
        SEND_VERDICT(NF_ACCEPT, MARK_NONE, NULL);
        goto end;
    }

    count_tcp_packet();

    // Level 2: session lookup
    struct session_key skey;
    if (ct_ok) {
        skey = session_key_from_connid(pkt->conn_id);
    } else {
        // Build five-tuple from IP/TCP headers
        struct ip_tuple tuple;
        memset(&tuple, 0, sizeof(tuple));
        tuple.ip_version = type;
        if (type == IPV4) {
            const __auto_type ip_hdr = nfq_ip_get_hdr(pkt_buff);
            if (ip_hdr != NULL) {
                tuple.src.ip4 = ip_hdr->saddr;
                tuple.dst.ip4 = ip_hdr->daddr;
            }
        } else {
            const __auto_type ip_hdr = nfq_ip6_get_hdr(pkt_buff);
            if (ip_hdr != NULL) {
                memcpy(&tuple.src.in6, &ip_hdr->ip6_src, sizeof(struct in6_addr));
                memcpy(&tuple.dst.in6, &ip_hdr->ip6_dst, sizeof(struct in6_addr));
            }
        }
        tuple.src_port = ntohs(tcp_hdr->th_sport);
        tuple.dst_port = ntohs(tcp_hdr->th_dport);
        skey = session_key_from_tuple(&tuple);
    }

    bool new_session = false;
    struct http_session *session = NULL;

    // Check if this looks like HTTP before creating session
    // (avoids session allocation for non-HTTP traffic)
    session_wrlock();
    session = session_find(&skey);
    if (session != NULL) {
        if (!session_retain_locked(session)) {
            session = NULL;
        }
    }

    if (session == NULL) {
        // No existing session — check if this looks like HTTP via fast path
        if (!is_http_protocol((const char *)tcp_payload, tcp_payload_len)) {
            session_wrunlock();
            // Not HTTP
            if (ct_ok) {
                add_to_cache(pkt);
                SEND_VERDICT(NF_ACCEPT, MARK_NOT_HTTP, NULL);
            } else {
                SEND_VERDICT(NF_ACCEPT, MARK_NONE, NULL);
            }
            goto end;
        }

        // Looks like HTTP — create session
        session = session_create(&skey);
        if (session == NULL) {
            session_wrunlock();
            syslog(LOG_WARNING, "Session limit reached, dropping packet");
            SEND_VERDICT(NF_DROP, MARK_NONE, NULL);
            goto end;
        }
        http_parser_init_session(session);
        if (!session_retain_locked(session)) {
            session_delete(session);
            session = NULL;
        } else {
            new_session = true;
        }
    }

    if (session == NULL) {
        session_wrunlock();
        syslog(LOG_ERR, "HTTP session unexpectedly missing");
        SEND_VERDICT(NF_DROP, MARK_NONE, NULL);
        goto end;
    }
    session_wrunlock();

    // Level 3: feed to llhttp (session is valid, protected by its own state lock)
    session_state_lock(session);
    session_reset_per_packet(session, tcp_payload);
    const int parse_ret = http_parser_feed(session, (const char *)tcp_payload, tcp_payload_len);

    // Copy results out before releasing lock
    const int ua_count = session->ua_entry_count;
    struct ua_mangle_entry ua_entries_copy[UA_MAX_ENTRIES];
    if (ua_count > 0) {
        memcpy(ua_entries_copy, session->ua_entries, ua_count * sizeof(struct ua_mangle_entry));
    }
    session_state_unlock(session);

    if (parse_ret != 0) {
        session_wrlock();
        session_delete(session);
        session_wrunlock();
        session_release(session);
        session = NULL;

        if (ct_ok) {
            add_to_cache(pkt);
            SEND_VERDICT(NF_ACCEPT, MARK_NOT_HTTP, NULL);
        } else {
            SEND_VERDICT(NF_ACCEPT, MARK_NONE, NULL);
        }
        goto end;
    }

    session_release(session);
    session = NULL;

    // Mangle UA entries (using copied data, session lock released)
    for (int i = 0; i < ua_count; i++) {
        const size_t ua_offset = ua_entries_copy[i].offset;
        const size_t ua_len = ua_entries_copy[i].len;
        const size_t replacement_offset = ua_entries_copy[i].replacement_offset;
        if (ua_offset > UINT_MAX || ua_len > UINT_MAX) {
            syslog(LOG_WARNING, "Skipping too-large user agent mangle entry");
            continue;
        }
        char *owned_replacement = NULL;
        const char *replacement = replacement_chunk(replacement_offset, ua_len, &owned_replacement);
        if (replacement == NULL) {
            syslog(LOG_ERR, "Failed to allocate replacement chunk");
            goto end;
        }

        if (type == IPV4) {
            if (!nfq_tcp_mangle_ipv4(pkt_buff, (unsigned int)ua_offset, (unsigned int)ua_len, replacement,
                                     (unsigned int)ua_len)) {
                free(owned_replacement);
                syslog(LOG_ERR, "Failed to mangle ipv4 packet");
                goto end;
            }
        } else {
            if (!nfq_tcp_mangle_ipv6(pkt_buff, (unsigned int)ua_offset, (unsigned int)ua_len, replacement,
                                     (unsigned int)ua_len)) {
                free(owned_replacement);
                syslog(LOG_ERR, "Failed to mangle ipv6 packet");
                goto end;
            }
        }
        free(owned_replacement);
    }

    if (ua_count > 0) {
        count_user_agent_packet();
    }

    SEND_VERDICT(NF_ACCEPT, (ct_ok && new_session) ? MARK_HTTP : MARK_NONE, pkt_buff);

end:
    if (!verdict_sent) {
        SEND_VERDICT(NF_ACCEPT, MARK_NONE, NULL);
    }
    free(pkt->payload);
    if (pkt_buff != NULL) {
        pktb_free(pkt_buff);
    }

    try_print_statistics();
#undef SEND_VERDICT
}
