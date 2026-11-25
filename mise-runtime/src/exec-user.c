/* SPDX-License-Identifier: GPL-3.0-only */
/* Root-only privilege drop for the fixed public runtime entry; never setuid. */
#include <errno.h>
#include <grp.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

static unsigned long identity(const char *text) {
    char *end;
    if (!*text || *text < '0' || *text > '9') goto invalid;
    errno = 0;
    unsigned long value = strtoul(text, &end, 10);
    if (errno || *end || value == 0 || value >= 0xffffffffUL) goto invalid;
    return value;
invalid:
    fputs("A positive non-root UID/GID is required\n", stderr);
    exit(126);
}

int main(int argc, char **argv) {
    if (getuid() != 0 || geteuid() != 0 || argc < 5) {
        fputs("Administrator required: exec-user UID GID INSTANCE COMMAND [ARGS...]\n", stderr);
        return 126;
    }
    unsigned long uid = identity(argv[1]), gid = identity(argv[2]);
    if ((unsigned long)(uid_t)uid != uid || (unsigned long)(gid_t)gid != gid) return 126;
    char **program = calloc((size_t)argc, sizeof(*program));
    if (!program) return 126;
    program[0] = "/usr/sbin/mise-runtime";
    program[1] = "exec";
    for (int i = 3; i < argc; i++) program[i - 1] = argv[i];
    if (setgroups(0, NULL) || setgid((gid_t)gid) || setuid((uid_t)uid)) {
        perror("Cannot drop runtime privileges");
        return 126;
    }
    /* No fork/session: caller signals, stdin and exact child status survive. */
    execv(program[0], program);
    perror("Cannot execute fixed runtime");
    return 126;
}
