#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syslog.h>
#include <unistd.h>

#include "cli.h"

#ifdef UA2F_ENABLE_UCI
#include "config.h"
#endif

bool cli_mode_set = false;
enum ua2f_mode cli_mode = UA2F_MODE_NFQUEUE;
bool cli_listen_port_set = false;
uint16_t cli_listen_port = UA2F_DEFAULT_PROXY_PORT;

void startup_message() {
    syslog(LOG_INFO, "UA2F version: %s", UA2F_VERSION);
    syslog(LOG_INFO, "Git commit: %s", UA2F_GIT_COMMIT);
    syslog(LOG_INFO, "Git branch: %s", UA2F_GIT_BRANCH);
    syslog(LOG_INFO, "Git tag: %s", UA2F_GIT_TAG);
}

static void print_usage(FILE *stream) {
    fprintf(stream, "Usage: ua2f [options]\n");
    fprintf(stream, "  -m, --mode NFQUEUE|REDIRECT|TPROXY  (default: %s)\n", ua2f_mode_name(UA2F_MODE_NFQUEUE));
    fprintf(stream, "  -p, --listen-port PORT              (default: %u)\n",
            (unsigned)UA2F_DEFAULT_PROXY_PORT);
    fprintf(stream, "  --version\n");
    fprintf(stream, "  --help\n");
}

static void print_mode_info(void) {
    printf("Supported modes: NFQUEUE, REDIRECT, TPROXY\n");
    printf("Default mode: %s\n", ua2f_mode_name(UA2F_MODE_NFQUEUE));
    printf("Default listen port: %u\n", (unsigned)UA2F_DEFAULT_PROXY_PORT);
}

static const char *read_option_value(int argc, char *argv[], int *index, const char *option) {
    const size_t option_len = strlen(option);
    if (strncmp(argv[*index], option, option_len) == 0 && argv[*index][option_len] == '=') {
        return argv[*index] + option_len + 1;
    }

    if (strcmp(argv[*index], option) == 0) {
        if (*index + 1 >= argc) {
            fprintf(stderr, "Missing value for %s\n", option);
            print_usage(stderr);
            exit(EXIT_FAILURE);
        }
        (*index)++;
        return argv[*index];
    }

    return NULL;
}

static bool parse_listen_port(const char *value, uint16_t *port) {
    char *endptr = NULL;
    const long parsed = strtol(value, &endptr, 10);
    if (endptr == value || *endptr != '\0' || parsed <= 0 || parsed > 65535) {
        return false;
    }

    *port = (uint16_t)parsed;
    return true;
}

// handle print --version and --help
void try_print_info(const int argc, char *argv[]) {
    if (argc < 2) {
        startup_message();
        return;
    }

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--version") == 0) {
            printf("UA2F version: %s\n", UA2F_VERSION);
            printf("Git commit: %s\n", UA2F_GIT_COMMIT);
            printf("Git branch: %s\n", UA2F_GIT_BRANCH);
            printf("Git tag: %s\n", UA2F_GIT_TAG);
            printf("Git dirty: %s\n", UA2F_GIT_DIRTY);
#ifdef UA2F_USE_CUSTOM_UA
            printf("Embed UA: %s\n", UA2F_CUSTOM_UA);
#else
            printf("Embed UA: not set\n");
#endif

            print_mode_info();

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
            printf("Config mode: %s\n", ua2f_mode_name(config.mode));
            printf("Config listen port: %u\n", (unsigned)config.listen_port);
            printf("Config NFQUEUE workers: %d\n", config.nfqueue_workers);
            if (config.proxy_workers > 0) {
                printf("Config proxy workers: %d\n", config.proxy_workers);
            } else {
                printf("Config proxy workers: auto\n");
            }
#else
            printf("UCI support disabled\n");
#ifdef UA2F_NO_CACHE
            printf("Conntrack cache: disabled\n");
#else
            printf("Conntrack cache: auto\n");
#endif
#endif

            exit(EXIT_SUCCESS);
        }

        if (strcmp(argv[i], "--help") == 0) {
            print_usage(stdout);
            exit(EXIT_SUCCESS);
        }

        const char *mode_value = read_option_value(argc, argv, &i, "--mode");
        if (mode_value == NULL && strcmp(argv[i], "-m") == 0) {
            mode_value = read_option_value(argc, argv, &i, "-m");
        }
        if (mode_value != NULL) {
            if (!ua2f_parse_mode(mode_value, &cli_mode)) {
                fprintf(stderr, "Invalid mode: %s\n", mode_value);
                print_usage(stderr);
                exit(EXIT_FAILURE);
            }
            cli_mode_set = true;
            continue;
        }

        const char *port_value = read_option_value(argc, argv, &i, "--listen-port");
        if (port_value == NULL) {
            port_value = read_option_value(argc, argv, &i, "--port");
        }
        if (port_value == NULL && strcmp(argv[i], "-p") == 0) {
            port_value = read_option_value(argc, argv, &i, "-p");
        }
        if (port_value != NULL) {
            if (!parse_listen_port(port_value, &cli_listen_port)) {
                fprintf(stderr, "Invalid listen port: %s\n", port_value);
                print_usage(stderr);
                exit(EXIT_FAILURE);
            }
            cli_listen_port_set = true;
            continue;
        }

        printf("Unknown option: %s\n", argv[i]);
        print_usage(stdout);
        exit(EXIT_FAILURE);
    }

    startup_message();
}

void require_root() {
    if (geteuid() != 0) {
        fprintf(stderr, "This program must be run as root\n");
        exit(EXIT_FAILURE);
    }
}
