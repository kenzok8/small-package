#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "cli.h"
#include "config.h"

// handle print --version and --help
void try_print_info(const int argc, char *argv[]) {
    if (argc != 2) {
        return;
    }

    if (strcmp(argv[1], "--version") == 0) {
        printf("UA2F version: %s\n", UA2F_VERSION);
        printf("Git commit: %s\n", UA2F_GIT_COMMIT);
        printf("Git branch: %s\n", UA2F_GIT_BRANCH);
        printf("Git tag: %s\n", UA2F_GIT_TAG);
#ifdef UA2F_CUSTOM_UA
        printf("Embed UA: %s\n", UA2F_CUSTOM_UA);
#else
        printf("Embed UA: not set\n");
#endif

#ifdef UA2F_ENABLE_UCI
        if (config.use_custom_ua) {
            printf("Config UA: %s\n", config.custom_ua);
        } else {
            printf("Config UA: not set\n");
        }
#else
        printf("UCI support disabled\n");
#endif
        exit(0);
    }

    if (strcmp(argv[1], "--help") == 0) {
        printf("Usage: ua2f\n");
        printf("  --version\n");
        printf("  --help\n");
        exit(0);
    }

    printf("Unknown option: %s\n", argv[1]);
    printf("Usage: ua2f\n");
    printf("  --version\n");
    printf("  --help\n");
    exit(1);
}