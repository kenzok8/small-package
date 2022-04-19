#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pppd/pppd.h"
typedef unsigned char byte;
//TODO : change the version here
char pppd_version[] = PPPOE_VER;

static unsigned char saveuser[MAXNAMELEN] = {0};
static unsigned char savepwd[MAXSECRETLEN] = {0};

int pap_modifyaccount()
{
	uint8_t len_user;
	uint8_t len_passwd;
	FILE *dF = fopen ("/var/Last_AuthReq", "r");
	if(dF){
		fread(&len_user,1,1,dF);
		fread(&saveuser,1,len_user,dF);
		fread(&len_passwd,1,1,dF);
		fread(&savepwd,1,len_passwd,dF);
		fflush(dF);
	}
	fclose(dF);
	dF=NULL;
	strcpy(user, saveuser);
	strcpy(passwd, savepwd);
}

static int check()
{
    return 1;
}

void plugin_init(void)
{
    pap_modifyaccount();
    info("Netkeeper-interception: Account Loaded");
    pap_check_hook=check;
    chap_check_hook=check;
}
