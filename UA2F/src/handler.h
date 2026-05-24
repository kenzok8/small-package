#ifndef UA2F_HANDLER_H
#define UA2F_HANDLER_H

#include "packet_io.h"
#include "third/nfqueue-mnl/nfqueue-mnl.h"

#include <stddef.h>

#define CONNMARK_NOT_HTTP 43
#define CONNMARK_HTTP 44
#define UA2F_MAX_USER_AGENT_LENGTH (0xffff + (MNL_SOCKET_BUFFER_SIZE / 2))

extern bool use_conntrack;
extern const struct packet_io nfqueue_packet_io;

void init_handler();

const char *get_replacement_user_agent_string();
size_t get_replacement_user_agent_string_length();

void handle_packet(const struct packet_io *io, void *io_ctx, const struct nf_packet *pkt);

#endif // UA2F_HANDLER_H
