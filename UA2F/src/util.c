#include <stddef.h>
#include <string.h>
#include <ctype.h>

void *memncasemem(const void *l, size_t l_len, const void *s, size_t s_len) {
    register char *cur, *last;
    const char *cl = (const char *) l;
    const char *cs = (const char *) s;

    /* we need something to compare */
    if (l_len == 0 || s_len == 0)
        return NULL;

    /* "s" must be smaller or equal to "l" */
    if (l_len < s_len)
        return NULL;

    /* special case where s_len == 1 */
    if (s_len == 1){
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