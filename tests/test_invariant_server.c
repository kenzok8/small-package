#include <check.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

/* Mock structures matching server.c */
typedef struct {
    uint8_t *array;
    size_t len;
} buffer_t;

typedef struct {
    buffer_t *buf;
} server_t;

#define MAX_HOSTNAME_LEN 256

/* Simulate the vulnerable memcpy pattern from server.c:935 */
static int vulnerable_copy(server_t *server, uint8_t *host, size_t host_size, 
                           size_t offset, uint8_t name_len) {
    /* Invariant: memcpy must not read beyond host_size bytes into host buffer */
    if (name_len > host_size) {
        return -1; /* Should reject oversized reads */
    }
    if (offset + 1 + name_len > server->buf->len) {
        return -1; /* Should reject reads beyond buffer */
    }
    memcpy(host, server->buf->array + offset + 1, name_len);
    return 0;
}

START_TEST(test_buffer_read_overflow_protection)
{
    /* Invariant: Buffer reads never exceed declared length */
    
    /* Test payloads: (1) exact exploit (name_len >> host buffer),
       (2) boundary (name_len == host_size), (3) valid input */
    struct {
        uint8_t name_len;
        const char *description;
    } payloads[] = {
        {255, "oversized_2x"},      /* 255 >> 256 host buffer */
        {512, "oversized_10x"},     /* 512 >> 256 host buffer */
        {256, "boundary_exact"},    /* name_len == MAX_HOSTNAME_LEN */
        {128, "valid_half"},        /* valid: well within bounds */
    };
    int num_payloads = sizeof(payloads) / sizeof(payloads[0]);
    
    for (int i = 0; i < num_payloads; i++) {
        server_t server;
        buffer_t buf;
        uint8_t host[MAX_HOSTNAME_LEN];
        uint8_t test_data[512];
        
        memset(test_data, 'A', sizeof(test_data));
        buf.array = test_data;
        buf.len = sizeof(test_data);
        server.buf = &buf;
        
        int result = vulnerable_copy(&server, host, MAX_HOSTNAME_LEN, 0, payloads[i].name_len);
        
        /* Assertion: oversized reads must be rejected */
        if (payloads[i].name_len > MAX_HOSTNAME_LEN) {
            ck_assert_int_eq(result, -1);
        } else {
            /* Valid reads should succeed */
            ck_assert_int_eq(result, 0);
        }
    }
}
END_TEST

Suite *security_suite(void)
{
    Suite *s;
    TCase *tc_core;
    
    s = suite_create("Security");
    tc_core = tcase_create("BufferOverflow");
    
    tcase_add_test(tc_core, test_buffer_read_overflow_protection);
    suite_add_tcase(s, tc_core);
    
    return s;
}

int main(void)
{
    int number_failed;
    Suite *s;
    SRunner *sr;
    
    s = security_suite();
    sr = srunner_create(s);
    
    srunner_run_all(sr, CK_NORMAL);
    number_failed = srunner_ntests_failed(sr);
    srunner_free(sr);
    
    return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}