/* A thin ELF entry preserves pip's ELF-based musl ABI detection while the
 * protected Lua dispatcher supplies persistent HOME and a fixed interpreter.
 * musl SDKs use a dynamic musl build; GNU SDKs use the same static build so
 * packaging never mistakes the native bootstrap for a musl Python process. */
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char **argv) {
    char self[PATH_MAX];
    ssize_t size = readlink("/proc/self/exe", self, sizeof(self) - 1);
    if (size < 1 || (size_t)size >= sizeof(self) - 1) {
        fputs("Cannot resolve fixed Python entry\n", stderr);
        return 126;
    }
    self[size] = '\0';
    char **args = calloc((size_t)argc + 3, sizeof(*args));
    if (!args) return 126;
    args[0] = "/usr/bin/lua";
    args[1] = "/usr/share/mise-runtime/python-launch.lua";
    args[2] = self;
    for (int i = 1; i < argc; i++) args[i + 2] = argv[i];
    execv(args[0], args);
    perror("Cannot execute fixed Python dispatcher");
    free(args);
    return 126;
}
