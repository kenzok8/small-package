#ifndef _UI_COMMON_H_
#define _UI_COMMON_H_

#ifdef __cplusplus
extern "C" {
#endif

/*********************
 *      INCLUDES
 *********************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lvgl/lvgl.h"
#include "fetch_data.h"

/**********************
 *      TYPEDEFS
 **********************/

#define __DEBUG    //日志模块总开关，注释将关闭全局日志输出

#ifdef __DEBUG
    #define APP_DEBUG(format, ...) printf ("\033[41;33m"format"\033[0m\n", ##__VA_ARGS__)
#else
    #define APP_DEBUG(format, ...)
#endif

#if 0
#define ASSET_PATH   "A:ui_entry/assets/"
#define FONT_PATH   "./ui_entry/assets/"
#else
#define ASSET_PATH   "/usr/share/lcdsimple/assets/"
#define FONT_PATH   "/usr/share/lcdsimple/assets/"
#endif

typedef enum
{
    E_KEY_EVENT = 0,
    E_EVENT_ID_MAX,
} Event_ID_t;

typedef enum
{
    E_K1 = 0,   // 循环切换
    E_K2,       // 强度循环/往左
    E_K3,       // 时间循环/往右
    E_K4,       // 开机/启动/停止
} BTN_ID_t;

typedef enum
{
    E_S_CLICKED = 0,
    E_L_CLICKED,
} BTN_STATUS_t;

typedef struct {
    Event_ID_t eEventID;    // 事件类型
    uint32_t lDataArray[2]; // lDataArray[0]-按键编号 lDataArray[1]-按键事件类型(长短按)
} Event_Data_t, *p_Event_Data_t;

typedef struct _SCR_FUNC_TYPE
{
    void (*load_func)(void *args);
    void (*refr_func)(Event_Data_t *args);  // NULL - 定时类显示刷新， 数值波动较大的, 不为NULL - 实时类显示刷新
    void (*quit_func)(void *args);
} SCR_FUNC_TYPE, *p_SCR_FUNC_TYPE;

typedef enum {
    E_HOME_SCR = 0,
    E_INFO_SCR,
    E_TOP_LAYER,
    E_MAX_SCR,
} E_SCREEN_ID;

typedef struct _SYS_PARM_TYPE{
    int status;
} SYS_PARM_TYPE, *p_SYS_PARM_TYPE;

typedef struct _SCR_LIST_TYPE{
    lv_obj_t *scr;
    SCR_FUNC_TYPE *user_data;
} SCR_LIST_TYPE, *p_SCR_LIST_TYPE;

typedef enum {
    DISP_SMALL,
    DISP_MEDIUM,
    DISP_LARGE,
} disp_size_t;

extern E_SCREEN_ID info_sid;
extern E_SCREEN_ID home_sid;
extern const lv_font_t *font_shs_10b;
extern const lv_font_t *font_shs_12b;
extern const lv_font_t *font_shs_16b;
extern const lv_font_t *font_shs_10r;
extern const lv_font_t *font_shs_8b;
extern const lv_font_t *font_mont_16;
extern char *icon1_path;
extern char *icon2_path;
extern char *icon3_path;
extern int disp_hor;
extern int disp_ver;

extern lv_obj_t *test_area;
extern lv_obj_t *test_area2;
extern lv_obj_t *arc1;
extern lv_obj_t *arc2;
extern lv_obj_t *top_cont;
extern lv_obj_t *info_table1;
extern lv_obj_t *info_table2;

/**********************
 * GLOBAL PROTOTYPES
 **********************/

void scr_add_user_data(lv_obj_t *scr, E_SCREEN_ID id, SCR_FUNC_TYPE *desc);
void scr_load_func(E_SCREEN_ID id, void *args);
void scr_quit_func(void *args);
void scr_refr_func(Event_Data_t *args);
E_SCREEN_ID scr_act_get(void);
void click_load_scr_event_cb(lv_event_t * e);


extern SYS_PARM_TYPE sys_parm;
extern E_SCREEN_ID g_scr_id[E_MAX_SCR];

/*********************
 *      DEFINES
 *********************/


/**********************
 *      MACROS
 **********************/

void lv_font_init(void);
void home_scr_create(void);
void top_layer_create(void);
void home_scr_update(void);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /*_UI_COMMON_H_*/
