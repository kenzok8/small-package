#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include "cJSON.h"
#include "fetch_data.h"

static monitor_info_t s_monitor_info = {0};

monitor_info_t* get_monitor_info() {
  return &s_monitor_info;
}

static int shell_with_pipe(char *cmd, char *buf, int len)
{
    FILE *fp = popen(cmd, "r");
    if (fp == NULL) return 0;
    char *ret = fgets(buf, len, fp);
    pclose(fp);
    return ret == NULL ? -1 : 0;
}

int read_info_from_shell(int use_disk) 
{
  char buf[16*1024];
  int err = 0, i, size;
  cJSON *json = NULL, *tmp, *arr, *item;
  disk_info_t *disk = NULL;
  char *with_disk_str = "curl --fail --silent --max-time 3 --unix-socket /var/run/quickstart/local.sock http://localhost/api/lcd/simple/";
  char *without_disk_str = "curl --fail --silent --max-time 3 --unix-socket /var/run/quickstart/local.sock http://localhost/api/lcd/simple/?disk=0";
  char *tmpc = NULL;
  monitor_info_t *info = &s_monitor_info;
  if (use_disk) {
    err = shell_with_pipe(with_disk_str, buf, 16*1024-1);
  } else {
    err = shell_with_pipe(without_disk_str, buf, 16*1024-1);
  }

  info->docker_ok = 0;
  info->linkease_ok = 0;
  info->domestic_link = 0;
  info->foreign_link = 0;
  info->cpu = 0;
  info->memory = 0;
  info->temperature = 0;
  info->devices = 0;
  info->net_err[0] = '\0';
  info->upload_str[0] = '\0';
  info->download_str[0] = '\0';
  info->ipv4[0] = '\0';
  info->ipv6[0] = '\0';
  info->public_ipv4[0] = '\0';
  info->dns[0] = '\0';
  info->domain[0] = '\0';

  if (0 != err) {
    fprintf(stderr, "curl err=%d\n", err);
    return -1;
  }

  json = cJSON_Parse(buf);
  if(NULL == json) {
    err = -2;
    return err;
  }
  do {
    tmp = cJSON_GetObjectItem(json, "dockerOk");
    if (NULL != tmp) {
      info->docker_ok = tmp->valueint;
    }

    tmp = cJSON_GetObjectItem(json, "linkeaseOk");
    if (NULL != tmp) {
      info->linkease_ok = tmp->valueint;
    }

    tmp = cJSON_GetObjectItem(json, "domesticLink");
    if (NULL != tmp) {
      info->domestic_link = tmp->valueint;
    }

    tmp = cJSON_GetObjectItem(json, "foreignLink");
    if (NULL != tmp) {
      info->foreign_link = tmp->valueint;
    }

    tmp = cJSON_GetObjectItem(json, "cpu");
    if (NULL != tmp) {
      info->cpu = tmp->valueint;
    } 

    tmp = cJSON_GetObjectItem(json, "memory");
    if (NULL != tmp) {
      info->memory = tmp->valueint;
    } 

    tmp = cJSON_GetObjectItem(json, "temp1");
    if (NULL != tmp) {
      info->temperature = tmp->valueint;
    } 

    tmp = cJSON_GetObjectItem(json, "devices");
    if (NULL != tmp) {
      info->devices = tmp->valueint;
    } 

    tmp = cJSON_GetObjectItem(json, "upload");
    if (NULL != tmp && cJSON_IsString(tmp)) {
      strncpy(info->upload_str, cJSON_GetStringValue(tmp), sizeof(info->upload_str)-1);
    }

    tmp = cJSON_GetObjectItem(json, "download");
    if (NULL != tmp && cJSON_IsString(tmp)) {
      strncpy(info->download_str, cJSON_GetStringValue(tmp), sizeof(info->download_str)-1);
    }

	  // Enum: [netDetecting netSuccess dnsFailed netFailed softSourceFailed]
    tmp = cJSON_GetObjectItem(json, "netErr");
    if (NULL != tmp && cJSON_IsString(tmp) && strlen(cJSON_GetStringValue(tmp)) > 0) {
      tmpc = cJSON_GetStringValue(tmp);
      if (0 == strcmp(tmpc, "dhcpError")) {
        strcpy(info->net_err, "地址分配错误");
      } else if (0 == strcmp(tmpc, "dnsFailed")) {
        strcpy(info->net_err, "域名错误");
      } else if (0 == strcmp(tmpc, "softSourceFailed")) {
        strcpy(info->net_err, "软件源错误");
      } else if (0 == strcmp(tmpc, "netFailed")) {
        strcpy(info->net_err, "网络错误");
      } else if (0 == strcmp(tmpc, "netDetecting")) {
        strcpy(info->net_err, "检测中");
      } else if (0 == strcmp(tmpc, "netSuccess")) {
        info->net_err[0] = '\0';
      } else {
        strcpy(info->net_err, tmpc);
      }
    }

    tmp = cJSON_GetObjectItem(json, "ipv4");
    if (NULL != tmp && cJSON_IsString(tmp)) {
      strncpy(info->ipv4, cJSON_GetStringValue(tmp), sizeof(info->ipv4)-1);
    }

    tmp = cJSON_GetObjectItem(json, "ipv6");
    if (NULL != tmp && cJSON_IsString(tmp)) {
      strncpy(info->ipv6, cJSON_GetStringValue(tmp), sizeof(info->ipv6)-1);
    }

    tmp = cJSON_GetObjectItem(json, "publicIpv4");
    if (NULL != tmp && cJSON_IsString(tmp)) {
      strncpy(info->public_ipv4, cJSON_GetStringValue(tmp), sizeof(info->public_ipv4)-1);
    }

    arr = cJSON_GetObjectItem(json, "dnsList");
    if (NULL != arr && cJSON_IsArray(arr)) {
      size = cJSON_GetArraySize(arr);
      if (size > 0) {
        tmp = cJSON_GetArrayItem(arr, 0);
        if (NULL != tmp && cJSON_IsString(tmp)) {
          strncpy(info->dns, cJSON_GetStringValue(tmp), sizeof(info->dns)-1);
        }
      }
    }

    tmp = cJSON_GetObjectItem(json, "uptimeHuman");
    if (NULL != tmp && cJSON_IsString(tmp)) {
      strncpy(info->uptime_human, cJSON_GetStringValue(tmp), sizeof(info->uptime_human)-1);
    }

    if (use_disk) {
      arr = cJSON_GetObjectItem(json, "disks");
    } else{
      arr = NULL;
    }
    if (NULL != arr && cJSON_IsArray(arr)) {
      memset(info->disks, 0, sizeof(info->disks));
      for (i = 0; i < sizeof(info->disks)/sizeof(info->disks[0]); i++) {
        info->disks[i].used_percent = -1;
      }
      size = cJSON_GetArraySize(arr);
      for (i = 0; i < size; i++) {
        disk = &info->disks[i];
        tmp = cJSON_GetArrayItem(arr, i);
        if(NULL != tmp) {
          item = cJSON_GetObjectItem(tmp, "isRoot");
          if(NULL != item && item->valueint != 0) { 
            disk->is_root = 1;
          }
          item = cJSON_GetObjectItem(tmp, "name");
          if(NULL != item && cJSON_IsString(item)) {
            strncpy(disk->name, cJSON_GetStringValue(item), sizeof(disk->name)-1);
          }
          item = cJSON_GetObjectItem(tmp, "used");
          if(NULL != item && cJSON_IsString(item)) {
            strncpy(disk->used, cJSON_GetStringValue(item), sizeof(disk->used)-1);
          }
          item = cJSON_GetObjectItem(tmp, "total");
          if(NULL != item && cJSON_IsString(item)) {
            strncpy(disk->total, cJSON_GetStringValue(item), sizeof(disk->total)-1);
          }
          item = cJSON_GetObjectItem(tmp, "usedPercent");
          if(NULL != item) { 
            disk->used_percent = item->valueint;
          }
        }
      }
    } 

  }while(0);

  cJSON_Delete(json);
  return err;
}

