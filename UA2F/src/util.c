#include <stddef.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

void *memncasemem(const void *l, size_t l_len, const void *s, const size_t s_len) {
    register char *cur, *last;
    const char *cl = l;
    const char *cs = s;

    /* we need something to compare */
    if (l_len == 0 || s_len == 0)
        return NULL;

    /* "s" must be smaller or equal to "l" */
    if (l_len < s_len)
        return NULL;

    /* special case where s_len == 1 */
    if (s_len == 1) {
        for (cur = (char *) cl; l_len--; cur++)
            if (tolower(cur[0]) == tolower(cs[0]))
                return cur;
    }

    /* the last position where its possible to find "s" in "l" */
    last = (char *) cl + l_len - s_len;

    for (cur = (char *) cl; cur <= last; cur++)
        if (tolower(cur[0]) == tolower(cs[0])) {
            if (strncasecmp(cur, cs, s_len) == 0) {
                return cur;
            }
        }

    return NULL;
}

static bool probe_http_method(const char *p, const int len, const char *opt) {
    if (len < strlen(opt)) {
        return false;
    }

    return !strncmp(p, opt, strlen(opt));
}

bool is_http_protocol(const char *p, const unsigned int len) {
    bool pass = false;

#define PROBE_HTTP_METHOD(opt) if ((pass = probe_http_method(p, len, opt)) != false) return pass

    PROBE_HTTP_METHOD("GET");
    PROBE_HTTP_METHOD("POST");
    PROBE_HTTP_METHOD("OPTIONS");
    PROBE_HTTP_METHOD("HEAD");
    PROBE_HTTP_METHOD("PUT");
    PROBE_HTTP_METHOD("DELETE");
    PROBE_HTTP_METHOD("TRACE");
    PROBE_HTTP_METHOD("CONNECT");

#undef PROBE_HTTP_METHOD
    return false;
}