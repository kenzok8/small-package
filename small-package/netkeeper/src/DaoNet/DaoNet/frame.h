//
//  frame.h
//  DaoNet
//
//  Created by realityone on 15/9/27.
//  Copyright © 2015年 realityone. All rights reserved.
//

#ifndef frame_h
#define frame_h

#include <stdio.h>
#include <sys/types.h>

#define MAX_FRAME_NAME_LEN 32
#define MAX_CONTENT_LEN 256

extern char dao_key[8];

typedef struct dao_param {
    const char *key;
    const char *value;
}dao_param;

typedef struct dao_frame {
    const char type[MAX_FRAME_NAME_LEN];
    char content[MAX_CONTENT_LEN];
}dao_frame;

void dao_frame_init(dao_frame *frame, const char *type);
size_t dao_frame_update(dao_frame *frame, dao_param *param);

char *calc_pin();

size_t dao_frame_to_data(dao_frame *src_frame, u_char *output);
#endif /* frame_h */
