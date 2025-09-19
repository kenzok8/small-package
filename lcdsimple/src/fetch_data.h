#ifndef __FETCH_DATA_
#define __FETCH_DATA_

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

typedef struct 
{
  char name[32];
  char used[32];
  char total[32];
  int is_root;
  int used_percent;
} disk_info_t;

typedef struct
{
  int docker_ok;
  int linkease_ok;
  int domestic_link;
  int foreign_link;
  int32_t cpu;
  int32_t memory;
  int32_t temperature;
  int devices;
  char net_err[32];
  char upload_str[16];
  char download_str[16];
  char ipv4[32];
  char ipv6[64];
  char public_ipv4[64];
  char dns[32];
  char domain[128];
  char uptime_human[32];

  disk_info_t disks[8];

  int request_cnt;
  int idle;
  int tick;
} monitor_info_t;

monitor_info_t* get_monitor_info();
int read_info_from_shell(int use_disk);

#ifdef __cplusplus
}
#endif

#endif

