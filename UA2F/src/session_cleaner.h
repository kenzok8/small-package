#ifndef UA2F_SESSION_CLEANER_H
#define UA2F_SESSION_CLEANER_H

void init_session_cleaner(int ttl_seconds, int interval_seconds);
int session_cleaner_run_once(int ttl_seconds);

#endif
