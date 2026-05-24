#ifndef UA2F_CLI_H
#define UA2F_CLI_H

#include "custom.h"
#include "mode.h"

#include <stdbool.h>
#include <stdint.h>

#ifndef UA2F_GIT_COMMIT
#define UA2F_GIT_COMMIT "unknown"
#endif

#ifndef UA2F_GIT_BRANCH
#define UA2F_GIT_BRANCH "unknown"
#endif

#ifndef UA2F_GIT_TAG
#define UA2F_GIT_TAG "unknown"
#endif

#ifndef UA2F_VERSION
#define UA2F_VERSION "unknown"
#endif

void try_print_info(int argc, char *argv[]);

void require_root();

extern bool cli_mode_set;
extern enum ua2f_mode cli_mode;
extern bool cli_listen_port_set;
extern uint16_t cli_listen_port;

#endif // UA2F_CLI_H
