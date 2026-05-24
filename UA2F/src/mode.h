#ifndef UA2F_MODE_H
#define UA2F_MODE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define UA2F_DEFAULT_PROXY_PORT 10010
#define UA2F_PROXY_SO_MARK 0xc9
#define UA2F_TPROXY_MARK 0x1c9
#define UA2F_TPROXY_TABLE 0x1c9

enum ua2f_mode {
    UA2F_MODE_NFQUEUE = 0,
    UA2F_MODE_REDIRECT,
    UA2F_MODE_TPROXY,
};

static inline char ua2f_ascii_tolower(char c) {
    if (c >= 'A' && c <= 'Z') {
        return (char)(c + ('a' - 'A'));
    }
    return c;
}

static inline bool ua2f_ascii_equal_fold(const char *a, const char *b) {
    if (a == NULL || b == NULL) {
        return false;
    }

    while (*a != '\0' && *b != '\0') {
        if (ua2f_ascii_tolower(*a) != ua2f_ascii_tolower(*b)) {
            return false;
        }
        a++;
        b++;
    }

    return *a == '\0' && *b == '\0';
}

static inline bool ua2f_parse_mode(const char *value, enum ua2f_mode *mode) {
    if (ua2f_ascii_equal_fold(value, "NFQUEUE")) {
        *mode = UA2F_MODE_NFQUEUE;
        return true;
    }
    if (ua2f_ascii_equal_fold(value, "REDIRECT")) {
        *mode = UA2F_MODE_REDIRECT;
        return true;
    }
    if (ua2f_ascii_equal_fold(value, "TPROXY")) {
        *mode = UA2F_MODE_TPROXY;
        return true;
    }

    return false;
}

static inline const char *ua2f_mode_name(enum ua2f_mode mode) {
    switch (mode) {
    case UA2F_MODE_NFQUEUE:
        return "NFQUEUE";
    case UA2F_MODE_REDIRECT:
        return "REDIRECT";
    case UA2F_MODE_TPROXY:
        return "TPROXY";
    default:
        return "UNKNOWN";
    }
}

#endif // UA2F_MODE_H
