//
//  frame.c
//  DaoNet
//
//  Created by realityone on 15/9/27.
//  Copyright © 2015年 realityone. All rights reserved.
//

#include "frame.h"

#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <mbedtls/md5.h>

char dao_key[8];
static dao_param dao_key_param = {"KEY", dao_key};

void dao_frame_init(dao_frame *frame, const char *type) {
    if (strlen(type) > MAX_FRAME_NAME_LEN) {
        fprintf(stderr, "ERROR: Frame type name too long, it should be under 15 characters.\n");
        exit(-1);
    }
    bzero(frame, sizeof(dao_frame));
    strcpy((char *)frame->type, type);
}

size_t dao_frame_update(dao_frame *frame, dao_param *param) {
    char *pcontent;
    int frame_content_len;
    
    frame_content_len = (int)strlen(frame->content);

    if (frame_content_len > 0) {
        frame->content[frame_content_len] = '&';
        pcontent = &frame->content[frame_content_len+1];
    } else {
        pcontent = &frame->content[frame_content_len];
    }
    
    sprintf(pcontent, "%s=%s", param->key, param->value);
    
    return strlen(frame->content);
}

size_t dao_frame_to_data(dao_frame *src_frame, u_char *output) {
    if (strlen(dao_key_param.value)) {
        dao_frame_update(src_frame, &dao_key_param);
    }
    sprintf((char *)output, "TYPE=%s&%s", src_frame->type, src_frame->content);
    return strlen((char *)output);
}

char *calc_pin() {
    static char pin[64];
    
    if (strlen(pin)) {
        return pin;
    }
    
    char before_md5[32];
    u_char after_md5[16];
    time_t timestamp;
    char *(salt[3]) = {"wanglei", "zhangni", "wangtianyou"};
    
    timestamp = time(NULL);
    sprintf(before_md5, "%08x", (int)timestamp);
    strcat(before_md5, salt[timestamp % 3]);
    
    mbedtls_md5((u_char *)before_md5, strlen(before_md5), after_md5);
    
    sprintf(pin, "%c%c%02x%02x%c%c%02x%02x%02x%02x%02x%02x%02x%02x%c%c%02x%02x%02x%c%c%02x%02x%02x",
            before_md5[0], before_md5[1], after_md5[0], after_md5[1], before_md5[2], before_md5[3], after_md5[2],
            after_md5[3], after_md5[4], after_md5[5], after_md5[6], after_md5[7], after_md5[8], after_md5[9],
            before_md5[4], before_md5[5], after_md5[10], after_md5[11], after_md5[12], before_md5[6], before_md5[7],
            after_md5[13], after_md5[14], after_md5[15]);
    return pin;

}