#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/syslog.h>

#include "cli.h"

#include "config.h"

void startup_message() {
    syslog(LOG_INFO, "UA2F version: %s", UA2F_VERSION);
    syslog(LOG_INFO, "Git commit: %s", UA2F_GIT_COMMIT);
    syslog(LOG_INFO, "Git branch: %s", UA2F_GIT_BRANCH);
    syslog(LOG_INFO, "Git tag: %s", UA2F_GIT_TAG);
}

// handle print --version and --help
void try_print_info(const int argc, char *argv[]) {
    if (argc < 2) {
        startup_message();
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

        if (config.disable_connmark) {
            printf("Conntrack cache: disabled\n");
        } else {
            printf("Conntrack cache: auto\n");
        }
#else
        printf("UCI support disabled\n");
#endif
        exit(EXIT_SUCCESS);
    }

    if (strcmp(argv[1], "--help") == 0) {
        printf("Usage: ua2f\n");
        printf("  --version\n");
        printf("  --help\n");
        exit(EXIT_SUCCESS);
    }

    printf("Unknown option: %s\n", argv[1]);
    printf("Usage: ua2f\n");
    printf("  --version\n");
    printf("  --help\n");
    exit(EXIT_FAILURE);
}

void require_root() {
    if (geteuid() != 0) {
        fprintf(stderr, "This program must be run as root\n");
        exit(EXIT_FAILURE);
    }
}