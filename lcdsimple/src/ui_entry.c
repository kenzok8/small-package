#include "ui_common.h"
#include <stdio.h>
#include <stdlib.h>

// 480x360

// #define VIRTUAL_KEYBORAD
// #define FREETYPE_EN

#ifdef FREETYPE_EN
lv_ft_info_t info_8ms_r;
#endif

static int event_lock = 0;  // 0-开机 1-关机
static lv_obj_t *black_mask = NULL;  // 屏保

#ifdef VIRTUAL_KEYBORAD
char label_name[4][16] = {"K1", "K2", "K3", "K4"};
static Event_Data_t xReceivedEvent = {
    .eEventID = 0xff,
}; 
void label_key_event_handler(lv_event_t * e)
{
    lv_obj_t *obj = lv_event_get_target(e);
    lv_event_code_t code = lv_event_get_code(e);
    if ((code == LV_EVENT_SHORT_CLICKED) || (code == LV_EVENT_LONG_PRESSED))
    {
        char *key_name = lv_label_get_text(obj);

        if (!strcmp(key_name, "K1"))
        {
            xReceivedEvent.eEventID = E_KEY_EVENT;
            xReceivedEvent.lDataArray[0] = E_K1;

            lv_obj_set_size(test_area, 480, 320);
            lv_obj_set_size(test_area2, 480, 320);
        }
        else if (!strcmp(key_name, "K2"))
        {
            xReceivedEvent.eEventID = E_KEY_EVENT;
            xReceivedEvent.lDataArray[0] = E_K2;

            lv_obj_set_size(test_area, 1024, 600);
            lv_obj_set_size(test_area2, 1024, 600);
        }
        else if (!strcmp(key_name, "K3"))
        {
            xReceivedEvent.eEventID = E_KEY_EVENT;
            xReceivedEvent.lDataArray[0] = E_K3;

            lv_obj_set_size(test_area, 1280, 720);
            lv_obj_set_size(test_area2, 1280, 720);
        }
        else if (!strcmp(key_name, "K4"))
        {
            xReceivedEvent.eEventID = E_KEY_EVENT;
            xReceivedEvent.lDataArray[0] = E_K4;

            extern void clear_info_table(void);
            extern void update_info_table(void);
            lv_obj_set_size(test_area, 1280, 480);
            lv_obj_set_size(test_area2, 1280, 480);
        }
        if(code == LV_EVENT_SHORT_CLICKED)
            xReceivedEvent.lDataArray[1] = E_S_CLICKED;
        else if(code == LV_EVENT_LONG_PRESSED)
            xReceivedEvent.lDataArray[1] = E_L_CLICKED;
        APP_DEBUG("%s %s", key_name, xReceivedEvent.lDataArray[1] ? "E_L_CLICKED" : "E_S_CLICKED");
    
        lv_obj_update_layout(test_area);
        lv_obj_update_layout(test_area2);
        int arc_size = (lv_obj_get_width(lv_obj_get_parent(arc1)) < lv_obj_get_height(lv_obj_get_parent(arc1)) ? lv_obj_get_width(lv_obj_get_parent(arc1)) : lv_obj_get_height(lv_obj_get_parent(arc1))) - 5;
        lv_obj_set_size(arc1, arc_size, arc_size);
        lv_obj_set_size(arc2, arc_size, arc_size);

        lv_obj_set_style_arc_width(arc1, arc_size / 10, 0);
        lv_obj_set_style_arc_width(arc1, arc_size / 10, LV_PART_INDICATOR);
        lv_obj_set_style_arc_width(arc2, arc_size / 10, 0);
        lv_obj_set_style_arc_width(arc2, arc_size / 10, LV_PART_INDICATOR);

        // clear_info_table();
        // update_info_table();
        lv_obj_update_layout(info_table1);
        lv_obj_update_layout(info_table2);
        lv_table_set_col_width(info_table1, 0, lv_obj_get_width(info_table1) / 4);
        lv_table_set_col_width(info_table1, 1, lv_obj_get_width(info_table1) / 4);
        lv_table_set_col_width(info_table1, 2, lv_obj_get_width(info_table1) / 4);
        lv_table_set_col_width(info_table1, 3, lv_obj_get_width(info_table1) / 4);
        lv_table_set_col_width(info_table2, 0, lv_obj_get_width(info_table2) / 3);
        lv_table_set_col_width(info_table2, 1, lv_obj_get_width(info_table2) / 3);
        lv_table_set_col_width(info_table2, 2, lv_obj_get_width(info_table2) / 3);

    }
}
lv_obj_t *vir_area;
void virtual_keyborad(void)
{
    vir_area = lv_obj_create(lv_layer_top());
    lv_obj_set_size(vir_area, 120, 30);
    lv_obj_align(vir_area, LV_ALIGN_TOP_LEFT, 0, 0);
    lv_obj_set_style_bg_color(vir_area, lv_color_white(), 0);
    lv_obj_set_style_border_width(vir_area, 0, 0);
    lv_obj_clear_flag(vir_area, LV_OBJ_FLAG_SCROLLABLE);

    for (int i = 0; i < 4; i++)
    {
        lv_obj_t *label = lv_label_create(vir_area);
        lv_label_set_text(label, label_name[i]);
        lv_obj_set_style_text_font(label, &lv_font_montserrat_12, 0);
        lv_obj_set_style_text_color(label, lv_color_make(10, 10, 10), 0);
        lv_obj_align(label, LV_ALIGN_LEFT_MID, i * 23 + 5, 0);
        lv_obj_add_event_cb(label, label_key_event_handler, LV_EVENT_SHORT_CLICKED, NULL);
        lv_obj_add_event_cb(label, label_key_event_handler, LV_EVENT_LONG_PRESSED, NULL);
        lv_obj_add_flag(label, LV_OBJ_FLAG_CLICKABLE);
    }
}
#endif

static void memory_print(void)
{
    lv_mem_monitor_t mon;
    lv_mem_monitor(&mon);
    APP_DEBUG("used: %6d (%3d %%), frag: %3d %%, biggest free: %6d", (int)mon.total_size - mon.free_size,
        mon.used_pct,
        mon.frag_pct,
        (int)mon.free_biggest_size);
}

static void scr_refr_task(struct _lv_timer_t* t)	// 500ms
{
    scr_refr_func(NULL);    // 定时读取电量，刷新显示
#ifdef VIRTUAL_KEYBORAD
    if(xReceivedEvent.eEventID != 0xff)   //判断是否队列是否存在新数据
    {
        if(xReceivedEvent.eEventID == E_KEY_EVENT)
        {
            if((xReceivedEvent.lDataArray[0] == E_K4) && (xReceivedEvent.lDataArray[1] == E_L_CLICKED))
            {
                event_lock = !event_lock;   // 开关机  关闭pwm
                scr_load_func(E_HOME_SCR, NULL);
                if (event_lock)
                {
                    APP_DEBUG("turn off device!");
                    lv_obj_clear_flag(black_mask, LV_OBJ_FLAG_HIDDEN);
                }
                else
                {
                    APP_DEBUG("turn on device!");
                    lv_obj_add_flag(black_mask, LV_OBJ_FLAG_HIDDEN);
                }
            }
            else if(!event_lock)
            {
                scr_refr_func(&xReceivedEvent);
            }
        }
    }
    xReceivedEvent.eEventID = 0xff;
#else
    Event_Data_t xReceivedEvent;
    scr_refr_func(&xReceivedEvent); // 处理各类事件
#endif 
}

void user_task(struct _lv_timer_t *t)
{
#if 0   // 轮播
    // memory_print();
    static int i = 0;
    scr_load_func(i, NULL);
    i = i < E_TOP_LAYER - 1 ? i + 1 : E_HOME_SCR;
#else   // 打印设备状态信息
    
#endif
}

static void bootlogo_del(struct _lv_anim_t *a)
{
    lv_obj_del(a->var);
    scr_load_func(E_HOME_SCR, NULL);
}

static void bootlogo_init(void)
{
    lv_obj_t *logo = lv_img_create(lv_scr_act());
    lv_img_set_src(logo, ASSET_PATH"logo.png");
    lv_obj_center(logo);

    lv_anim_t a;
    lv_anim_init(&a);
    lv_anim_set_var(&a, logo);
    lv_anim_set_ready_cb(&a, bootlogo_del);
    lv_anim_set_time(&a, 1000);
    lv_anim_set_repeat_delay(&a, 500);
    lv_anim_set_values(&a, 0, 100);
    lv_anim_start(&a);
}

void lv_ui_entry(void)
{
#ifdef FREETYPE_EN
    info_8ms_r.name = FONT_PATH"8ms.ttf";
    info_8ms_r.weight = 12;
    info_8ms_r.style = FT_FONT_STYLE_NORMAL;
    info_8ms_r.mem = NULL;
    if(!lv_ft_font_init(&info_8ms_r)) {
        LV_LOG_ERROR("create failed.");
    }
#endif
    //disp_hor = LV_HOR_RES; 
    //disp_ver = LV_VER_RES;
    lv_font_init();
    home_scr_create();
    //info_scr_create();
    top_layer_create();
    bootlogo_init();    // 开机logo -> 1s后跳转到主界面 bootlogo_del

    black_mask = lv_obj_create(lv_layer_top());
    lv_obj_set_size(black_mask, LV_HOR_RES, LV_VER_RES);
    lv_obj_set_style_bg_color(black_mask, lv_color_black(), 0);
    lv_obj_set_style_radius(black_mask, 0, 0);
    lv_obj_set_style_border_width(black_mask, 0, 0);
    lv_obj_add_flag(black_mask, LV_OBJ_FLAG_HIDDEN);

#ifdef VIRTUAL_KEYBORAD
    virtual_keyborad();
#endif

    lv_timer_t *t1 = lv_timer_create(user_task, 3000, NULL);
    lv_timer_t *t2 = lv_timer_create(scr_refr_task, 100, NULL); // 100ms 读取系统参数并自动刷新界面 - 目前仅用于实现电量图标刷新， 可在此处实现按键事件接收并传递

}
