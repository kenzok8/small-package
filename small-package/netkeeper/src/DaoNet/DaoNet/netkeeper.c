//
//  netkeeper.c
//  DaoNet
//
//  Created by realityone on 15/9/27.
//  Copyright © 2015年 realityone. All rights reserved.
//

#include "netkeeper.h"

#include <stdlib.h>
#include <string.h>

void dao_aes_setup(dao_aes_ctx *ctx, int mode, const char *key) {
    size_t key_length;
    key_length = strlen(key);
    
    if (key_length != 16) {
        fprintf(stderr, "ERROR: Key length must be 16.");
        exit(-1);
    }
    
    bzero(ctx, sizeof(dao_aes_ctx));
    strcpy(ctx->key, key);

    mbedtls_aes_init(&ctx->aes_enc_ctx);
    if (mode == DAO_AES_ENCRYPT) {
        mbedtls_aes_setkey_enc(&ctx->aes_enc_ctx, (const u_char *)key, 128);
    } else if (mode == DAO_AES_DECRYPT) {
        mbedtls_aes_setkey_dec(&ctx->aes_dec_ctx, (const u_char *)key, 128);
    }
}

void dao_aes_free(dao_aes_ctx *ctx) {
    bzero(ctx->key, MAX_KEY_LENGTH);
    mbedtls_aes_free(&ctx->aes_enc_ctx);
}

size_t dao_aes_padding(u_char *input, size_t length, u_char *output) {
    int i;
    size_t padding_size;
    
    memcpy(output, input, length);
    padding_size = (block_size - length % block_size) % block_size;
    for (i = 0; i < padding_size; i++) {
        input[length + i] = padding_size;
    }
    return length + padding_size;
}

size_t dao_aes_process_data(dao_aes_ctx *ctx, int mode, u_char *input, size_t length, u_char *output) {
    int i;
    int times;
    u_char *pinput, *poutput;
    
    if (length % block_size) {
        fprintf(stderr, "ERROR: The length of input must be the multiple of %d, or please padding it first.\n", block_size);
        exit(-1);
    }
    
    pinput = input;
    poutput = output;
    times = (int)(length / block_size);
    for (i = 0; i < times; i++) {
        if (mode == DAO_AES_ENCRYPT) {
            mbedtls_aes_crypt_ecb(&ctx->aes_enc_ctx, mode, pinput, poutput);
        } else if (mode == DAO_AES_DECRYPT) {
            mbedtls_aes_crypt_ecb(&ctx->aes_dec_ctx, mode, pinput, poutput);
        }
        pinput += block_size;
        poutput += block_size;
    }
    return poutput - output;
}

size_t dao_aes_encrypt(dao_aes_ctx *ctx, u_char *input, size_t length, u_char *output) {
    return dao_aes_process_data(ctx, MBEDTLS_AES_ENCRYPT, input, length, output);
}

size_t dao_aes_decrypt(dao_aes_ctx *ctx, u_char *input, size_t length, u_char *output) {
    return dao_aes_process_data(ctx, MBEDTLS_AES_DECRYPT, input, length, output);
}

void dao_protocol_init(dao_protocol *protocol, const u_short version, const u_short code) {
    bzero(protocol, sizeof(dao_protocol));
    protocol->magic_num = magic_num;
    protocol->version = version;
    protocol->code = code;
}

void dao_protocol_set_content(dao_protocol *protocol, u_char *content, size_t length) {
    memcpy(protocol->content, content, length);
    protocol->content_length = length;
}

size_t dao_protocol_generate_data(dao_protocol *protocol, u_char *output) {
    u_char *position;
    u_short magic_num_le;
    u_short code_le;
    u_int content_length_le;
    
    position = output;
    magic_num_le = htons(protocol->magic_num);
    content_length_le = htonl(protocol->content_length);
    
    // "HR"
    memcpy(position, &magic_num_le, sizeof(u_short));
    position += sizeof(u_short);
    
    // "30"
    sprintf((char *)position, "%d", protocol->version);
    position += sizeof(u_short);
    
    // 0x0205 or 0x05
    if (protocol->code & 0xFF00) {
        code_le = htons(protocol->code);
        memcpy(position, &code_le, sizeof(u_short));
        position += sizeof(u_short);
    } else {
        memcpy(position, &protocol->code, sizeof(u_short) / 2);
        position += sizeof(u_short) / 2;
    }
    
    // 0x000000b0
    memcpy(position, &content_length_le, sizeof(int));
    position += sizeof(int);
    
    // content
    memcpy(position, protocol->content, protocol->content_length);
    position += protocol->content_length + 1;
    
    return position - output - 1;
}