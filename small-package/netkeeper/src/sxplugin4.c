#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
//TODO : you may obtaion it by git clone https://github.com/squadette/pppd.git
#include "pppd/pppd.h"
#include "md5.h"
#define PREFIX0 '\r'
typedef unsigned char byte;
//TODO : change the version here
char pppd_version[] = PPPOE_VER;
char radius[] = RADIUS;

static char saveuser[MAXNAMELEN] = {0};
static char savepwd[MAXSECRETLEN] = {0};

static void getPIN(byte *userName, byte *PIN)
{
    int i, j;
    byte temp[32];
    long timedivbyfive;
    time_t timenow;   //Linux Stamp
    byte timeByte[4]; //time encryption from Linux Stamp
    MD5_CTX md5;      //MD5 class from pppd/md5.h
    byte afterMD5[16];
    byte beforeMD5[128] = {0};
    byte MD501H[2];
    byte MD501[3];

    byte timeHash[4]; //time encryption from timeByte
    byte PIN27[6];    //time encryption from timeHash
    timenow = time(NULL);
    info("-------------------------------------");
    info("timenow(Hex)=%x\n", timenow);
    timedivbyfive = timenow / 5;

    for (i = 0; i < 4; i++)
    {
        timeByte[i] = (byte)(timedivbyfive >> (8 * (3 - i)) & 0xFF);
    }

    //PIN27
    for (i = 0; i < 32; i++)
    {
        temp[i] = timeByte[(31 - i) / 8] & 1;
        timeByte[(31 - i) / 8] = timeByte[(31 - i) / 8] >> 1;
    }

    for (i = 0; i < 4; i++)
    {
        timeHash[i] = temp[i] * 128 + temp[4 + i] * 64 + temp[8 + i] * 32 + temp[12 + i] * 16 + temp[16 + i] * 8 + temp[20 + i] * 4 + temp[24 + i] * 2 + temp[28 + i];
    }

    temp[1] = (timeHash[0] & 3) << 4;
    temp[0] = (timeHash[0] >> 2) & 0x3F;
    temp[2] = (timeHash[1] & 0xF) << 2;
    temp[1] = (timeHash[1] >> 4 & 0xF) + temp[1];
    temp[3] = timeHash[2] & 0x3F;
    temp[2] = ((timeHash[2] >> 6) & 0x3) + temp[2];
    temp[5] = (timeHash[3] & 3) << 4;
    temp[4] = (timeHash[3] >> 2) & 0x3F;

    for (i = 0; i < 6; i++)
    {
        PIN27[i] = temp[i] + 0x020;
        if (PIN27[i] >= 0x40)
        {
            PIN27[i]++;
        }
    }
    //PIN
    PIN[0] = PREFIX0;
    PIN[1] = PREFIX1;

    info("Begin : beforeMD5");
    int a, b, c = 0;
    int np = strcspn(userName, "@");
    for (i = 0; i < 64; i++)
    {
        switch (i % 3)
        {
        case 0:
            if (a < np)
            {
                beforeMD5[i] = userName[a];
                a++;
                continue;
            }
            break;
        case 1:
            if (b < 6)
            {
                beforeMD5[i] = PIN27[b];
                b++;
                continue;
            }
            break;
        case 2:
            if (c < 32)
            {
                beforeMD5[i] = radius[c];
                c++;
                continue;
            }
            break;

        default:
            break;
        }

        if (b < 6)
        {
            beforeMD5[i] = PIN27[b];
            b++;
            continue;
        }
        if (c < 32)
        {
            beforeMD5[i] = radius[c];
            c++;
            continue;
        }
        beforeMD5[i] = i;
    }

    info("1.<%s>", beforeMD5);
    info("End : beforeMD5");

    info("Begin : afterMD5");
    MD5_Init(&md5);
    MD5_Update(&md5, beforeMD5, 64);
    MD5_Final(afterMD5, &md5); //generate MD5 sum

    byte x = afterMD5[((afterMD5[11] & 0xF0) >> 4)];
    byte y = afterMD5[((afterMD5[13] & 0x3C) >> 2)];
    byte z = afterMD5[(afterMD5[6] & 0x0F)];
    byte code = ((x & 0xF0) >> 6) + (y & 0x3C) + ((z & 0x0F) << 6);
    sprintf(MD501, "%02x", code);
    info("1.MD5use_1=<%2x>", MD501[0]);
    info("2.MD5use_2=<%2x>", MD501[1]);
    info("End : afterMD5");

    memcpy(PIN + 2, PIN27, 6);

    PIN[8] = MD501[0];
    PIN[9] = MD501[1];

    strcpy(PIN + 10, userName);
    info("-------------------------------------");
}

static int pap_modifyusername(char *user, char *passwd)
{
    byte PIN[MAXSECRETLEN] = {0};
    getPIN(saveuser, PIN);
    strcpy(user, PIN);
    info("sxplugin : user  is <%s> ", user);
}

static int check()
{
    return 1;
}

void plugin_init(void)
{
    info("sxplugin : init");
    strcpy(saveuser, user);
    strcpy(savepwd, passwd);
    pap_modifyusername(user, saveuser);
    info("sxplugin : passwd loaded");
    pap_check_hook = check;
    chap_check_hook = check;
}
