#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
// TODO : you may obtaion it by git clone https://github.com/squadette/pppd.git
#include "pppd/pppd.h"
#include "md5.h"

typedef unsigned char byte;
// TODO : change the version here
char pppd_version[] = PPPOE_VER;

static char saveuser[MAXNAMELEN] = {0};
static char savepwd[MAXSECRETLEN] = {0};

#define KEY_BUFF_LEN 32

u_short hash_key(char *key_string, int length) {
  int i;
  int key_hash = 0;
  char *pkey_string = key_string;

  for (i = 0; i < length / 2; i++) {
    key_hash += *(u_short *)pkey_string;
    pkey_string += 2;
  }

  if (length % 2) {
    key_hash += key_string[length - 1];
  }

  if (key_hash & 0xFFFF0000) {
    key_hash = ((key_hash >> 0x10) + key_hash) & 0xFFFF;
  }

  return (u_short)(~key_hash & 0xFFFF);
}

int new_calc_pin(char *username, char *buffer) {
  int i, j;
  int pos;
  time_t timestamp;
  u_short first_hash;
  u_short second_hash;
  u_char key_buff[KEY_BUFF_LEN];
  u_char *pkey_buff;
  u_char vectors[KEY_BUFF_LEN];

  char share_key[] = "hngx01";
  char sec_key[] = "000c29270712";
  char key_table[] =
      "abcdefghijklmnopqrstuvwxyz1234567890ZYXWVUTSRQPONMLKJIHGFEDCBA:_";

  timestamp = time(NULL);

  bzero(key_buff, KEY_BUFF_LEN);
  pkey_buff = key_buff;
  for (i = 0; i < 4; i++) {
    *pkey_buff = (timestamp >> (8 * (3 - i))) & 0xFF;
    pkey_buff++;
  }

  memcpy(pkey_buff, share_key, strlen(share_key));
  pkey_buff += strlen(share_key);
  memcpy(pkey_buff, username, strcspn(username, "@"));

  first_hash = hash_key((char *)key_buff, (int)strlen((char *)key_buff));
  info("first_hash: %x", first_hash);

  bzero(key_buff, KEY_BUFF_LEN);
  pkey_buff = key_buff;
  for (i = 0; i < 2; i++) {
    *pkey_buff = (first_hash >> (8 * (1 - i))) & 0xFF;
    pkey_buff++;
  }
  memcpy(pkey_buff, sec_key, strlen(sec_key));
  pkey_buff += strlen(sec_key);

  second_hash = hash_key((char *)key_buff, (int)strlen((char *)key_buff));
  info("second_hash: %x", second_hash);

  bzero(key_buff, KEY_BUFF_LEN);
  pkey_buff = key_buff;
  for (i = 0; i < 2; i++) {
    *pkey_buff = ((timestamp >> 16) >> (8 * (1 - i))) & 0xFF;
    pkey_buff++;
  }
  memcpy(pkey_buff, &first_hash, sizeof(u_short));
  pkey_buff += 2;
  for (i = 0; i < 2; i++) {
    *pkey_buff = (timestamp >> (8 * (1 - i))) & 0xFF;
    pkey_buff++;
  }
  memcpy(pkey_buff, &second_hash, sizeof(u_short));
  info("final_key: %s", key_buff);

  for (i = 0; i < 4; i++) {
    j = 2 * i + 1;
    pos = 3 * i + 1;
    vectors[pos - 1] = key_buff[j - 1] >> 0x3 & 0x1F;
    vectors[pos] =
        ((key_buff[j - 1] & 0x7) << 0x2) | (key_buff[j] >> 0x6 & 0x3);
    vectors[pos + 1] = key_buff[j] & 0x3F;
  }

  bzero(key_buff, KEY_BUFF_LEN);
  for (i = 0; i < 12; i++) {
    key_buff[i] = key_table[vectors[i]];
  }
  sprintf(buffer, "~LL_%s_%s", key_buff, username);

  return 0;
}

static int pap_modifyusername(char *user, char *passwd) {
  byte PIN[MAXSECRETLEN] = {0};
  new_calc_pin(saveuser, PIN);
  strcpy(user, PIN);
  info("sxplugin : user  is <%s> ", user);
}

static int check() { return 1; }

void plugin_init(void) {
  info("sxplugin : init");
  info("sxplugin : support for hainan singlenet");
  strcpy(saveuser, user);
  strcpy(savepwd, passwd);
  pap_modifyusername(user, saveuser);
  info("sxplugin : passwd loaded");
  pap_check_hook = check;
  chap_check_hook = check;
}
