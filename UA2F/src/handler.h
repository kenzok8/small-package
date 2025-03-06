#ifndef UA2F_HANDLER_H
#define UA2F_HANDLER_H

#include "third/nfqueue-mnl/nfqueue-mnl.h"

extern bool use_conntrack;

void init_handler();

void handle_packet(const struct nf_queue *queue, const struct nf_packet *pkt);

#endif // UA2F_HANDLER_H
