#ifndef UA2F_BACKTRACE_H
#define UA2F_BACKTRACE_H

#ifdef UA2F_ENABLE_BACKTRACE
#include <backtrace.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>

static void error_callback(void *data, const char *msg, int errnum) {
    fprintf(stderr, "libbacktrace error: %s (errno: %d)\n", msg, errnum);
}

static int full_callback(void *data, uintptr_t pc, const char *filename, int lineno, const char *function) {
    struct backtrace_state *state = (struct backtrace_state *)data;
    fprintf(stderr, "    %s:%d (%s)\n", filename ? filename : "??", lineno, function ? function : "??");
    return 0;
}

static void simple_callback(void *data, const char *msg) {
    fprintf(stderr, "libbacktrace: %s\n", msg);
}

static struct backtrace_state *get_backtrace_state(void) {
    static struct backtrace_state *state = NULL;
    if (!state) {
        state = backtrace_create_state(NULL, 0, error_callback, NULL);
    }
    return state;
}

static void signal_backtrace_handler(int signum) {
    fprintf(stderr, "Received signal %s (%d)\n", strsignal(signum), signum);
    fprintf(stderr, "Backtrace:\n");
    struct backtrace_state *state = get_backtrace_state();
    backtrace_full(state, 0, full_callback, error_callback, NULL);
    exit(EXIT_FAILURE);
}

static void signal_exit_handler(int signum) {
    fprintf(stderr, "Received signal %s (%d), exiting...\n", strsignal(signum), signum);
    exit(EXIT_SUCCESS);
}

#define UA2F_INIT_BACKTRACE() do { \
    signal(SIGSEGV, signal_backtrace_handler); \
    signal(SIGABRT, signal_backtrace_handler); \
    signal(SIGFPE, signal_backtrace_handler); \
    signal(SIGILL, signal_backtrace_handler); \
} while(0)

#else

#define UA2F_INIT_BACKTRACE() do { \
    fprintf(stderr, "Backtrace support is disabled\n"); \
} while(0)

#endif

#endif // UA2F_BACKTRACE_H 