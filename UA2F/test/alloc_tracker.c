#include "alloc_tracker.h"

#include <stdbool.h>
#include <stdlib.h>

static _Thread_local bool tracking;
static _Thread_local size_t fail_on_call;
static _Thread_local size_t allocation_calls;
static _Thread_local struct allocation_counts counts;

void *__real_malloc(size_t size);
void *__real_calloc(size_t count, size_t size);
void *__real_realloc(void *ptr, size_t size);
void __real_free(void *ptr);

void ua2f_test_alloc_begin(size_t fail_call) {
    counts = (struct allocation_counts){0};
    allocation_calls = 0;
    fail_on_call = fail_call;
    tracking = true;
}

struct allocation_counts ua2f_test_alloc_end(void) {
    tracking = false;
    return counts;
}

static bool fail_allocation(void) {
    allocation_calls++;
    return fail_on_call != 0 && allocation_calls == fail_on_call;
}

void *__wrap_malloc(size_t size) {
    if (tracking) {
        counts.malloc_calls++;
        if (fail_allocation()) {
            return NULL;
        }
    }
    return __real_malloc(size);
}

void *__wrap_calloc(size_t count, size_t size) {
    if (tracking) {
        counts.calloc_calls++;
        if (fail_allocation()) {
            return NULL;
        }
    }
    return __real_calloc(count, size);
}

void *__wrap_realloc(void *ptr, size_t size) {
    if (tracking) {
        counts.realloc_calls++;
        if (fail_allocation()) {
            return NULL;
        }
    }
    return __real_realloc(ptr, size);
}

void __wrap_free(void *ptr) {
    if (tracking && ptr != NULL) {
        counts.free_calls++;
    }
    __real_free(ptr);
}
