#include "lvgl/lvgl.h"
#include "lv_drivers/display/fbdev.h"
#include "lv_drivers/indev/evdev.h"
#include <unistd.h>
#include <pthread.h>
#include <time.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <sys/ioctl.h>
#include "ui_common.h"

#define DISP_BUF_SIZE (32*2048)

lv_timer_t *timer;
static void my_timer(lv_timer_t * _x);
static void update_by_monitor(monitor_info_t *info);

void get_fb_info(int *width, int *height) {
    int fb_fd = open(FBDEV_PATH, O_RDWR);
    if (fb_fd < 0) {
        perror("Error opening framebuffer device");
        return;
    }

    struct fb_var_screeninfo vinfo;
    if (ioctl(fb_fd, FBIOGET_VSCREENINFO, &vinfo)) {
        perror("Error reading variable information");
        close(fb_fd);
        return;
    }

    *width = vinfo.xres;
    *height = vinfo.yres;

    close(fb_fd);
}

int main(void)
{
    int width = 0;
    int height = 0;
    while(1) {
      get_fb_info(&width, &height);
      if(0 != width && 0 != height) {
        break;
      }
      sleep(3);
    }

    /*LittlevGL init*/
    lv_init();

    /*Linux frame buffer device init*/
    fbdev_init();

    //int width = LV_HOR_RES;
    //int height = LV_VER_RES;
    //printf("HDMI Resolution: %dx%d, %dx%d\n", width, height, LV_HOR_RES, LV_VER_RES);
    disp_hor = width; 
    disp_ver = height;

    /*A small buffer for LittlevGL to draw the screen's content*/
    static lv_color_t sbuf0[DISP_BUF_SIZE], sbuf1[DISP_BUF_SIZE];
    char *buf0 = sbuf0, *buf1 = sbuf1;;
    if(width > 2048) {
      buf0 = malloc(32*width);
      buf1 = malloc(32*width);
    }

    /*Initialize a descriptor for the buffer*/
    static lv_disp_draw_buf_t disp_buf;
    lv_disp_draw_buf_init(&disp_buf, buf0, buf1, DISP_BUF_SIZE);

    /*Initialize and register a display driver*/
    static lv_disp_drv_t disp_drv;
    lv_disp_drv_init(&disp_drv);
    disp_drv.draw_buf   = &disp_buf;
    disp_drv.flush_cb   = fbdev_flush;
    disp_drv.hor_res    = width;
    disp_drv.ver_res    = height;
    lv_disp_drv_register(&disp_drv);

#if USE_EVDEV == 1
    evdev_init();
    static lv_indev_drv_t indev_drv_1;
    lv_indev_drv_init(&indev_drv_1); /*Basic initialization*/
    indev_drv_1.type = LV_INDEV_TYPE_POINTER;

    /*This function will be called periodically (by the library) to get the mouse position and state*/
    indev_drv_1.read_cb = evdev_read;
    lv_indev_t *mouse_indev = lv_indev_drv_register(&indev_drv_1);
#endif

	#if 0
    /*Set a cursor for the mouse*/
    LV_IMG_DECLARE(mouse_cursor_icon)
    lv_obj_t * cursor_obj = lv_img_create(lv_scr_act()); /*Create an image object for the cursor */
    lv_img_set_src(cursor_obj, &mouse_cursor_icon);           /*Set the image source*/
    lv_indev_set_cursor(mouse_indev, cursor_obj);             /*Connect the image  object to the driver*/
	#endif


	lv_ui_entry();
  timer = lv_timer_create(my_timer, 2000, NULL);

    /*Handle LitlevGL tasks (tickless mode)*/
    while(1) {
        lv_timer_handler();
        usleep(1000);
    }

    return 0;
}

/*Set in lv_conf.h as `LV_TICK_CUSTOM_SYS_TIME_EXPR`*/
uint32_t custom_tick_get(void)
{
    static uint64_t start_ms = 0;
    if(start_ms == 0) {
        struct timeval tv_start;
        gettimeofday(&tv_start, NULL);
        start_ms = (tv_start.tv_sec * 1000000 + tv_start.tv_usec) / 1000;
    }

    struct timeval tv_now;
    gettimeofday(&tv_now, NULL);
    uint64_t now_ms;
    now_ms = (tv_now.tv_sec * 1000000 + tv_now.tv_usec) / 1000;

    uint32_t time_ms = now_ms - start_ms;
    return time_ms;
}

static void my_timer(lv_timer_t * _x)
{
  (void)(_x);
  monitor_info_t *info = get_monitor_info();
  update_by_monitor(info);
}

static void update_by_monitor(monitor_info_t *info) 
{
  int width = disp_hor;
  int height = disp_ver;
  int ret;
  if(info->request_cnt % 5 == 0) {
    get_fb_info(&width, &height);
    if(disp_hor != width || disp_ver != height) {
      exit(1);
      return;
    }
    ret = read_info_from_shell(1);
  } else {
    ret = read_info_from_shell(0);
  }
  info->request_cnt++;
  if (0 != ret) {
    fprintf(stderr, "curl ret=%d\n", ret);
    return;
  }
  home_scr_update();
}
