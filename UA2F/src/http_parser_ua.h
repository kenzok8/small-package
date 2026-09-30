#ifndef UA2F_HTTP_PARSER_UA_H
#define UA2F_HTTP_PARSER_UA_H

#include "http_session.h"

// Initialize llhttp parser and callbacks on a session.
void http_parser_init_session(struct http_session *session);

// Allocation failures must not be treated as non-HTTP traffic and forwarded.
#define HTTP_PARSER_NO_MEMORY (-2)

// Feed TCP payload to llhttp parser. Records entries accessible through session_ua_entry().
// Returns: 0 on success, -1 on parse error, HTTP_PARSER_NO_MEMORY on allocation failure.
int http_parser_feed(struct http_session *session, const char *data, size_t len);

#endif /* UA2F_HTTP_PARSER_UA_H */
