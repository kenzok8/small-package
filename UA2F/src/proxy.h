#ifndef UA2F_PROXY_H
#define UA2F_PROXY_H

#include "mode.h"

#include <signal.h>
#include <stdint.h>

int run_proxy(enum ua2f_mode mode, uint16_t listen_port, volatile sig_atomic_t *should_exit);

#endif // UA2F_PROXY_H
