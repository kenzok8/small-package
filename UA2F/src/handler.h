#ifndef UA2F_HANDLER_H
#define UA2F_HANDLER_H

#include "third/nfqueue-mnl.h"

void init_handler();

void handle_packet(struct nf_queue *queue, struct nf_packet *pkt);

#endif //UA2F_HANDLER_H
