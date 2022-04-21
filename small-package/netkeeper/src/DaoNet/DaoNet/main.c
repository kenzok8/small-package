//
//  main.c
//  DaoNet
//
//  Created by realityone on 15/9/27.
//  Copyright © 2015年 realityone. All rights reserved.
//

#include <stdio.h>
#include <sys/types.h>
#include <getopt.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <arpa/inet.h>

#include "frame.h"
#include "netutils.h"
#include "netkeeper.h"

#ifndef HEARTBEAT_NK4
static const char short_opts[] = "u:p:i:v:I:k:t:P:h";
static struct option long_options[] = {
    {"username", required_argument, NULL, 'u'},
    {"password", required_argument, NULL, 'p'},
    {"ip", required_argument, NULL, 'i'},
    {"version", required_argument, NULL, 'v'},
    {"interval", required_argument, NULL, 'I'},
    {"target", required_argument, NULL, 't'},
    {"port", required_argument, NULL, 'P'},
    {"aeskey", required_argument, NULL, 'k'},
    {"help", no_argument, NULL, 'h'},
    {NULL, 0, NULL, 0}
};
#else
static const char short_opts[] = "u:i:v:I:k:t:P:h:m";
static struct option long_options[] = {
    {"username", required_argument, NULL, 'u'},
    {"ip", required_argument, NULL, 'i'},
    {"version", required_argument, NULL, 'v'},
    {"interval", required_argument, NULL, 'I'},
    {"target", required_argument, NULL, 't'},
    {"port", required_argument, NULL, 'P'},
    {"aeskey", required_argument, NULL, 'k'},
    {"macaddress" , required_argument , NULL , 'm'},
    {"help", no_argument, NULL, 'h'},
    {NULL, 0, NULL, 0}
};
#endif

static struct UserConfig {
    const char username[32];
    const char password[16];
    const char ipaddress[16];
    const char version[16];
    const char aes_key[20];
    const char target[16];
    const char macaddr[19];
    int port;
    int interval;
}user_config;

#ifdef HEARTBEAT_NK4
/*
*   NetKeeper 的HTTP心跳就别想了，naive
*   
*   让我来看看有多少傻吊会拿着这份东西出去搞事情。
*
*   aes key = nk4*JLk^jk>cas*>
*/
static dao_param dao_params_array[] = {
    {"USER_NAME", user_config.username},
    {"PASSWORD", "NULL"},
    {"IP", user_config.ipaddress},
    {"MAC", user_config.macaddr}, //should be like 01-23-45-67-89-10
    {"DRIVER", "NULL"},
    {"VERSION_NUMBER", user_config.version},
    {"PIN", "0"},
    {NULL, NULL}
};
#elif defined( HEARTBEAT_HUBEI )
//Hubei Telecom Heartbeat using MAC Version 
//SVR = 58.53.196.172    PORT = 443
//KEY = xinli_zhejiang12
//
//湖北的云心跳的傻逼们，这是你们最后的狂欢
//请尽情展现你们最不要脸、最可耻、为了金钱丧心病狂无所不作的一面吧
//呵呵。
//
static dao_param dao_params_array[] = {
    {"USER_NAME", user_config.username},
    {"PASSWORD", user_config.password},
    {"IP", user_config.ipaddress},
    {"MAC", "00%2D00%2D00%2D00%2D00%2D00"},
    {"DRIVER", "1"},
    {"VERSION_NUMBER", "2.0.4"},
    {"PIN", "MAC_TEST"},
    {NULL, NULL}
   };
#else
static dao_param dao_params_array[] = {
    {"USER_NAME", user_config.username},
    {"PASSWORD", user_config.password},
    {"IP", user_config.ipaddress},
    {"MAC", "00%2D00%2D00%2D00%2D00%2D00"},
    {"DRIVER", "1"},
    {"VERSION_NUMBER", user_config.version},
    {"HOOK", ""},
    {"IP2", user_config.ipaddress},
    {NULL, NULL}
};
#endif

void print_usage() {
    fprintf(stdout, "Usage: daonet [OPTIONS]\n");
    fprintf(stdout, "Options:\n");
    fprintf(stdout, "  --username,  -u:      Username.\n");
    #ifndef HEARTBEAT_NK4
    fprintf(stdout, "  --password,  -p:      Password.\n");
    #else
    fprintf(stdout, "  --mac_address, -m:    Mac Address of Interface.\n");
    #endif
    fprintf(stdout, "  --ipaddress, -i:      IP Address.\n");
    fprintf(stdout, "  --version,   -v:      Version.\n");
    fprintf(stdout, "  --aeskey,    -k:      Aes key.\n");
    fprintf(stdout, "  --interval,  -I:      Interval.\n");
    fprintf(stdout, "  --target,    -t:      Target.\n");
    fprintf(stdout, "  --port,      -P:      Port.\n");
    fprintf(stdout, "  --help,      -h:      Help.\n");
    
    exit(0);
}

void validate_config() {
    if (!strlen(user_config.username) ||
        #ifndef  HEARTBEAT_NK4
        !strlen(user_config.password) ||
        #else
        !strlen(user_config.macaddr) ||
        #endif
        !strlen(user_config.ipaddress) ||
        !strlen(user_config.version) ||
        !strlen(user_config.target) ||
        !strlen(user_config.aes_key) ||
        
        !user_config.port ||
        !user_config.interval) {
        fprintf(stderr, "Missing arguments.\n");
        print_usage();
    }
}

void parse_args(int argc, const char * argv[]) {
    int opt;
    
    while ((opt = getopt_long(argc, (char *const *)argv, short_opts, long_options, NULL)) != -1) {
        switch (opt) {
            case 'h':
                print_usage();
                break;
                
            case 'u':
                strcpy((char *)user_config.username, optarg);
                break;
                
#ifndef HEARTBEAT_NK4
            case 'p':
                strcpy((char *)user_config.password, optarg);
                break;
#else    
            case 'm':
                strcpy((char *)user_config.macaddr, optarg);
                break;
#endif
                
            case 'i':
                strcpy((char *)user_config.ipaddress, optarg);
                break;
                
            case 'v':
                strcpy((char *)user_config.version, optarg);
                break;
                
            case 't':
                strcpy((char *)user_config.target, optarg);
                break;
                
            case 'k':
                strcpy((char *)user_config.aes_key, optarg);
                break;
                
            case 'P':
                user_config.port = atoi(optarg);
                break;
                
            case 'I':
                user_config.interval = atoi(optarg);
                break;
                
            default:
                print_usage();
                break;
        }
    }
    validate_config();
}

size_t generate_packet(dao_param *dao_params_array, const char *key, const char *aes_key, u_char *output) {
    int i;
    size_t frame_data_len;
    size_t content_data_len;
    u_char buffer[256];

    dao_frame HR30;
    dao_aes_ctx aes;
    dao_protocol procotol;
    
    dao_frame_init(&HR30, "HEARTBEAT");
    for (i = 0; dao_params_array[i].key && dao_params_array[i].value; i++) {
        dao_frame_update(&HR30, &dao_params_array[i]);
    }
    if (key != NULL) {
        strcpy(dao_key, key);
    }
    
    frame_data_len = dao_frame_to_data(&HR30, buffer);
    
    dao_aes_setup(&aes, DAO_AES_ENCRYPT, aes_key);
    frame_data_len = dao_aes_padding(buffer, frame_data_len, buffer);
    content_data_len = dao_aes_encrypt(&aes, buffer, frame_data_len, buffer);
    
#if defined(HEARTBEAT_HUBEI)
    dao_protocol_init(&procotol, 20, 0x05);
#elif defined(HEARTBEAT_NK4)
    dao_protocol_init(&procotol, 70, 0x05);
#else
    dao_protocol_init(&procotol, 30, 0x05);
#endif
    dao_protocol_set_content(&procotol, buffer, content_data_len);

    return dao_protocol_generate_data(&procotol, output);
}

size_t parse_packet(u_char *rcv_data, size_t length) {
    char *substring;
    u_char decrypt_buff[256];
    dao_aes_ctx aes;
    
    dao_aes_setup(&aes, DAO_AES_DECRYPT, user_config.aes_key);
    dao_aes_decrypt(&aes, rcv_data, length, decrypt_buff);
    if ((substring = strstr((char *)decrypt_buff, "KEY"))) {
        bzero(dao_key, 8);
        memcpy(dao_key, substring, 6);
    }

    return 6;
}

void main_loop(int argc, const char * argv[]) {
    int times;
    int sockfd;
    int result;
    size_t packet_len;
    struct sockaddr_in target_addr;
    struct timeval timeout = {2, 0};
    u_char packet_buffer[256];
    
    parse_args(argc, argv);
    bzero(packet_buffer, 256);
    
    sockfd = udp_init(user_config.target, user_config.port, &target_addr);
    udp_set_timeout(sockfd, timeout);
    
    times = 0;
    while (1) {
        times += 1;
        packet_len = generate_packet(dao_params_array, NULL, user_config.aes_key, packet_buffer);
        if ((result = (int)udp_sendto(sockfd, &target_addr, packet_buffer, packet_len)) > 0) {
            fprintf(stdout, "INFO: Send packet succeed.\n");
            bzero(packet_buffer, 256);
            if ((result = (int)udp_rcvfrom(sockfd, packet_buffer, packet_len)) > 0) {
                fprintf(stdout, "INFO: Recv packet succeed.\n");
                parse_packet(packet_buffer, result);
            } else {
                fprintf(stderr, "ERROR: Wait for packet timeout.\n");
            }
        } else {
            fprintf(stderr, "ERROR: Send packet failed.\n");
        }
        fprintf(stdout, "INFO: Wait %d seconds.\n", user_config.interval);
        sleep(user_config.interval);
    }
}

int main(int argc, const char * argv[]) {
    fprintf(stdout, "WARRNING: Support for ShanXi Netkeeper temporary.\n");
    main_loop(argc, argv);
    return 0;
}
