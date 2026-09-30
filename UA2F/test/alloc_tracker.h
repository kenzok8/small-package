#ifndef UA2F_TEST_ALLOC_TRACKER_H
#define UA2F_TEST_ALLOC_TRACKER_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

struct allocation_counts {
    size_t malloc_calls;
    size_t calloc_calls;
    size_t realloc_calls;
    size_t free_calls;
};

// Track only the synchronous region between begin/end; fail_call=0 never fails.
void ua2f_test_alloc_begin(size_t fail_call);
struct allocation_counts ua2f_test_alloc_end(void);

#ifdef __cplusplus
}
#endif

#endif
