#include "session_cleaner.h"
#include "http_session.h"

#include <pthread.h>
#include <syslog.h>
#include <unistd.h>

static int cleaner_ttl;
static int cleaner_interval;

int session_cleaner_run_once(const int ttl_seconds) {
    session_wrlock();
    const int deleted = session_cleanup_expired(ttl_seconds);
    session_wrunlock();

    if (deleted > 0) {
        syslog(LOG_INFO, "Session cleaner: removed %d expired sessions", deleted);
    }

    return deleted;
}

_Noreturn static void *cleaner_thread(void *arg __attribute__((unused))) {
    while (1) {
        sleep(cleaner_interval);
        session_cleaner_run_once(cleaner_ttl);
    }
}

void init_session_cleaner(const int ttl_seconds, const int interval_seconds) {
    cleaner_ttl = ttl_seconds;
    cleaner_interval = interval_seconds;

    pthread_t tid;
    if (pthread_create(&tid, NULL, cleaner_thread, NULL) != 0) {
        syslog(LOG_ERR, "Failed to create session cleaner thread");
        return;
    }
    pthread_detach(tid);
    syslog(LOG_INFO, "Session cleaner started (ttl=%ds, interval=%ds)", ttl_seconds, interval_seconds);
}
