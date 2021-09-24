//
//  netkeeper.h
//  DaoNet
//
//  Created by realityone on 15/9/27.
//  Copyright © 2015年 realityone. All rights reserved.
//

#ifndef netkeeper_h
#define netkeeper_h

#include <stdio.h>
#include <sys/types.h>

#include <mbedtls/aes.h>

#define MAX_KEY_LENGTH 24
#define DAO_AES_ENCRYPT MBEDTLS_AES_ENCRYPT
#define DAO_AES_DECRYPT MBEDTLS_AES_DECRYPT

typedef struct {
    char key[MAX_KEY_LENGTH];
    union {
        mbedtls_aes_context aes_enc_ctx;
        mbedtls_aes_context aes_dec_ctx;
    };
}dao_aes_ctx;

typedef struct {
    u_short magic_num;
    u_short version;
    u_short code;
    size_t content_length;
    u_char content[256];
}dao_protocol;

static const u_short magic_num = 0x4852;
static const u_short block_size = 16;

void dao_aes_setup(dao_aes_ctx *ctx, int mode, const char *key);
void dao_aes_free(dao_aes_ctx *ctx);
size_t dao_aes_padding(u_char *input, size_t length, u_char *output);
size_t dao_aes_encrypt(dao_aes_ctx *ctx, u_char *input, size_t length, u_char *output);
size_t dao_aes_decrypt(dao_aes_ctx *ctx, u_char *input, size_t length, u_char *output);

void dao_protocol_init(dao_protocol *protocol, const u_short version, const u_short code);
void dao_protocol_free(dao_protocol *protocol);
void dao_protocol_set_content(dao_protocol *protocol, u_char *content, size_t length);
size_t dao_protocol_generate_data(dao_protocol *protocol, u_char *output);

#endif /* netkeeper_h */
