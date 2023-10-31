#ifndef UA2F_UTIL_H
#define UA2F_UTIL_H

#include <string.h>
#include <stdbool.h>

#define QUEUE_NUM 10010

void *memncasemem(const void *l, size_t l_len, const void *s, size_t s_len);
bool is_http_protocol(const char *p, unsigned int len);

#endif //UA2F_UTIL_H
