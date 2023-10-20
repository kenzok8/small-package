#ifndef UA2F_CLI_H
#define UA2F_CLI_H

#include "custom.h"

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

#endif //UA2F_CLI_H
