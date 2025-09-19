#include "ui_common.h"
#include <stdio.h>
#include <time.h>

static lv_obj_t *home_scr;
static lv_obj_t *son_obj[5];
static int refr_lock = 1;

static void home_scr_obj_create(void);
static void home_scr_obj_delete(void);

static void home_scr_load_func(void *arg)
{
    // ... ui_init
    home_scr_obj_create();
    refr_lock = 0;
}

static void btn_event_handle(BTN_ID_t which, BTN_STATUS_t status)
{
    switch (which)
    {
    case E_K1:
        if (status == E_S_CLICKED)
            ;
        else
            ;
        break;
    case E_K2:
        if (status == E_S_CLICKED)
            ;
        else
            ;
        break;
    case E_K3:
        if (status == E_S_CLICKED)
            ;
        else
            ;
        break;
    case E_K4:
        if (status == E_S_CLICKED)
            ;
        else
            ;
        break;
    default:
        break;
    }
}

static void home_scr_refr_func(Event_Data_t *arg)
{
    if(refr_lock)
        return;
    if(arg == NULL)
    {
        
    }
    else
    {
        if(arg->eEventID == E_KEY_EVENT)
            btn_event_handle(arg->lDataArray[0], arg->lDataArray[1]);
    }
}

static void home_scr_quit_func(void *arg)
{
    refr_lock = 1;
    // ... ui_del
    home_scr_obj_delete();
}


static void home_scr_obj_create(void)
{

}

static void home_scr_obj_delete(void)
{

}

typedef struct disk_label_ {
  lv_obj_t *name;
  lv_obj_t *used;
  lv_obj_t *bar;
} disk_label_t;

lv_obj_t *err_label;
lv_obj_t *date_label;
lv_obj_t *time_label;
lv_obj_t *link_img;
lv_obj_t *link_label;
lv_obj_t *domestic_img;
lv_obj_t *foreign_img;
lv_obj_t *linkstatus_label;
lv_obj_t *domestic_label;
lv_obj_t *foreign_label;
lv_obj_t *up_label;
lv_obj_t *devices_label;
lv_obj_t *ipv4_label;
lv_obj_t *ipv6_label;
lv_obj_t *dns_label;
lv_obj_t *cpu_label;
lv_obj_t *cpu_arc;
lv_obj_t *temp_label;
lv_obj_t *temp_arc;
lv_obj_t *public_ipv4_label;
lv_obj_t *download_label;
lv_obj_t *upload_label;
lv_obj_t *domain_label;
disk_label_t disk_labels[3] = {0};

void home_scr_create(void)
{
    lv_obj_t *obj;
    lv_obj_t *img1;
    lv_obj_t *img2;
    lv_obj_t *label1;
    lv_obj_t *label2;
    lv_obj_t *label3;

    lv_color_t red_color = lv_color_make(255, 0, 0);
    home_scr = lv_obj_create(NULL);
    lv_obj_set_style_bg_color(home_scr, lv_color_black(), 0);

    static lv_coord_t col_dsc1[] = {LV_GRID_FR(268), LV_GRID_FR(176), LV_GRID_TEMPLATE_LAST};

    static lv_coord_t row_dsc1[] = {LV_GRID_FR(28), LV_GRID_FR(26), LV_GRID_FR(26), LV_GRID_FR(26), LV_GRID_FR(26),
                                LV_GRID_FR(26), LV_GRID_FR(26), LV_GRID_FR(16), LV_GRID_FR(16), LV_GRID_FR(16), 
                                LV_GRID_FR(16), LV_GRID_FR(16), LV_GRID_FR(16), LV_GRID_FR(16), LV_GRID_FR(16), 
                                LV_GRID_FR(16), LV_GRID_TEMPLATE_LAST};

    test_area = lv_obj_create(home_scr);
    lv_obj_set_style_bg_color(test_area, lv_color_black(), 0);
    lv_obj_set_size(test_area, disp_hor, disp_ver);
    lv_obj_center(test_area);
    lv_obj_set_grid_dsc_array(test_area, col_dsc1, row_dsc1);
    lv_obj_set_style_border_width(test_area, 0, 0);

    int ver_pad, hor_pad;
    if (disp_hor <= 480) {
      ver_pad = 4;
      hor_pad = 6;
    } else if (disp_hor <= 800) {
      ver_pad = 4*8;
      hor_pad = 4*8;
    } else {
      ver_pad = 4*10;
      hor_pad = 4*10;
    }
    lv_obj_set_style_pad_ver(test_area, ver_pad, 0);   // 容器上下左右边界
    lv_obj_set_style_pad_hor(test_area, hor_pad, 0);   // 容器上下左右边界
    lv_obj_set_style_pad_gap(test_area, 6, 0);   // 容器子对象间隔

    int col, row;

    col = 0; row = 0;
    son_obj[0] = lv_obj_create(test_area);
    lv_obj_set_grid_cell(son_obj[0], LV_GRID_ALIGN_STRETCH, col, 2,
                            LV_GRID_ALIGN_STRETCH, row, 1);

    col = 0; row = 1;
    son_obj[1] = lv_obj_create(test_area);
    lv_obj_set_grid_cell(son_obj[1], LV_GRID_ALIGN_STRETCH, col, 1,
                            LV_GRID_ALIGN_STRETCH, row, 6);

    col = 0; row = 7;
    son_obj[2] = lv_obj_create(test_area);
    lv_obj_set_grid_cell(son_obj[2], LV_GRID_ALIGN_STRETCH, col, 1,
                            LV_GRID_ALIGN_STRETCH, row, 9);

    col = 1; row = 1;
    son_obj[3] = lv_obj_create(test_area);
    lv_obj_set_grid_cell(son_obj[3], LV_GRID_ALIGN_STRETCH, col, 1,
                            LV_GRID_ALIGN_STRETCH, row, 6);

    col = 1; row = 7;
    son_obj[4] = lv_obj_create(test_area);
    lv_obj_set_grid_cell(son_obj[4], LV_GRID_ALIGN_STRETCH, col, 1,
                            LV_GRID_ALIGN_STRETCH, row, 9);

#if 1
    for(int i = 0; i < sizeof(son_obj) / sizeof(lv_obj_t *); i++)
    {
        lv_obj_update_layout(son_obj[i]);
        //printf("w = %d h = %d\n", lv_obj_get_width(son_obj[i]), lv_obj_get_height(son_obj[i]));
        lv_obj_clear_flag(son_obj[i], LV_OBJ_FLAG_SCROLLABLE);
        lv_obj_set_style_pad_all(son_obj[i], 0, 0);
        lv_obj_set_style_bg_color(son_obj[i], lv_color_make(20, 17, 39), 0);
        lv_obj_set_style_radius(son_obj[i], 0, 0);
        lv_obj_set_style_border_color(son_obj[i], lv_color_make(20, 17, 39), 0);
    }
    lv_obj_set_style_bg_opa(son_obj[0], 0, 0);
    lv_obj_set_style_border_width(son_obj[0], 0, 0);
    lv_obj_set_style_border_color(son_obj[2], lv_color_make(255, 187, 50), 0);
#endif

// ------------------------ col 0 row 2 -----------------------------
    obj = lv_obj_create(son_obj[2]);
    lv_obj_set_style_radius(obj, 0, 0);
    lv_obj_set_style_bg_color(obj, lv_color_make(255, 187, 50), 0);
    lv_obj_set_style_border_width(obj, 0, 0);
    lv_obj_set_style_pad_all(obj, 5, 0);
    lv_obj_set_size(obj, LV_PCT(100), LV_PCT(15));
    lv_obj_clear_flag(obj, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_align(obj, LV_ALIGN_TOP_MID, 0, 0);

    label1 = lv_label_create(obj);
    lv_obj_set_style_text_font(label1, font_shs_10b, 0);
    lv_obj_set_style_text_color(label1, lv_color_black(), 0);
    lv_label_set_text(label1, "外用网络状态:");
    lv_obj_align(label1, LV_ALIGN_LEFT_MID, 0, 0);

    obj = lv_obj_create(son_obj[2]);
    lv_obj_set_style_radius(obj, 0, 0);
    // lv_obj_set_style_bg_color(obj, lv_color_make(128, 255, 128), 0);
    lv_obj_set_style_bg_opa(obj, 0, 0);
    lv_obj_set_style_border_width(obj, 0, 0);
    lv_obj_set_style_pad_all(obj, 0, 0);
    lv_obj_set_size(obj, LV_PCT(100), LV_PCT(85));
    lv_obj_clear_flag(obj, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_align(obj, LV_ALIGN_BOTTOM_MID, 0, 0);

    static lv_coord_t col_dsc7[] = {LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};
    static lv_coord_t row_dsc7[] = {LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};
    lv_obj_set_grid_dsc_array(obj, col_dsc7, row_dsc7);
    lv_obj_set_style_pad_all(obj, 10, 0);

    label1 = lv_label_create(obj);
    lv_obj_set_style_text_font(label1, font_shs_10r, 0);
    lv_obj_set_style_text_color(label1, lv_color_make(184, 184, 190), 0);
    lv_label_set_text(label1, "公网IP:");

    label2 = lv_label_create(obj);
    lv_obj_set_style_text_font(label2, font_shs_12b, 0);
    lv_obj_set_style_text_color(label2, lv_color_white(), 0);
    lv_label_set_text(label2, "");
    public_ipv4_label = label2;

    lv_obj_set_grid_cell(label1, LV_GRID_ALIGN_START, 0, 1, LV_GRID_ALIGN_CENTER, 1, 1);
    lv_obj_set_grid_cell(label2, LV_GRID_ALIGN_START, 0, 1, LV_GRID_ALIGN_CENTER, 2, 1);

    label1 = lv_label_create(obj);
    lv_obj_set_style_text_font(label1, font_shs_10r, 0);
    lv_obj_set_style_text_color(label1, lv_color_make(184, 184, 190), 0);
    lv_label_set_text(label1, "下载");

    label2 = lv_label_create(obj);
    lv_obj_set_style_text_font(label2, font_shs_12b, 0);
    lv_obj_set_style_text_color(label2, lv_color_white(), 0);
    lv_label_set_text(label2, "0KB/s");
    download_label = label2;

    lv_obj_set_grid_cell(label1, LV_GRID_ALIGN_START, 2, 1, LV_GRID_ALIGN_CENTER, 1, 1);
    lv_obj_set_grid_cell(label2, LV_GRID_ALIGN_START, 2, 1, LV_GRID_ALIGN_CENTER, 2, 1);

    label1 = lv_label_create(obj);
    lv_obj_set_style_text_font(label1, font_shs_10r, 0);
    lv_obj_set_style_text_color(label1, lv_color_make(184, 184, 190), 0);
    lv_label_set_text(label1, "域名:");

    label2 = lv_label_create(obj);
    lv_obj_set_style_text_font(label2, font_shs_12b, 0);
    lv_obj_set_style_text_color(label2, lv_color_white(), 0);
    lv_label_set_text(label2, "");
    domain_label = label2;

    lv_obj_set_grid_cell(label1, LV_GRID_ALIGN_START, 0, 1, LV_GRID_ALIGN_CENTER, 3, 1);
    lv_obj_set_grid_cell(label2, LV_GRID_ALIGN_START, 0, 1, LV_GRID_ALIGN_CENTER, 4, 1);

    label1 = lv_label_create(obj);
    lv_obj_set_style_text_font(label1, font_shs_10r, 0);
    lv_obj_set_style_text_color(label1, lv_color_make(184, 184, 190), 0);
    lv_label_set_text(label1, "上传");

    label2 = lv_label_create(obj);
    lv_obj_set_style_text_font(label2, font_shs_12b, 0);
    lv_obj_set_style_text_color(label2, lv_color_white(), 0);
    lv_label_set_text(label2, "0KB/s");
    upload_label = label2;

    lv_obj_set_grid_cell(label1, LV_GRID_ALIGN_START, 2, 1, LV_GRID_ALIGN_CENTER, 3, 1);
    lv_obj_set_grid_cell(label2, LV_GRID_ALIGN_START, 2, 1, LV_GRID_ALIGN_CENTER, 4, 1);
    
    lv_obj_t *obj1 = lv_obj_create(obj);    // 百度连接、谷歌连接轨道
    lv_obj_set_style_radius(obj1, 0, 0);
    lv_obj_set_style_bg_opa(obj1, 0, 0);
    lv_obj_set_style_border_width(obj1, 0, 0);
    lv_obj_set_style_pad_all(obj1, 0, 0);
    lv_obj_set_style_pad_column(obj1, 5, 0);
    lv_obj_set_size(obj1, LV_SIZE_CONTENT, LV_SIZE_CONTENT);
    lv_obj_clear_flag(obj1, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_grid_cell(obj1, LV_GRID_ALIGN_STRETCH, 0, 4, LV_GRID_ALIGN_STRETCH, 0, 1);
    lv_obj_add_flag(obj1, LV_OBJ_FLAG_OVERFLOW_VISIBLE);

    static lv_coord_t col_dsc8[] = {LV_GRID_CONTENT, LV_GRID_CONTENT, 0, LV_GRID_CONTENT, LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};
    static lv_coord_t row_dsc8[] = {LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};

    lv_obj_set_grid_dsc_array(obj1, col_dsc8, row_dsc8);

    label1 = lv_label_create(obj1);
    lv_obj_set_style_text_font(label1, font_shs_10r, 0);
    lv_obj_set_style_text_color(label1, red_color, 0);
    lv_label_set_text(label1, "x");
    domestic_label = label1;
    label1 = lv_label_create(obj1);
    lv_obj_set_style_text_font(label1, font_shs_10r, 0);
    lv_obj_set_style_text_color(label1, red_color, 0);
    lv_label_set_text(label1, "x");
    foreign_label = label1;

    img1 = lv_img_create(obj1);
    lv_img_set_src(img1, icon1_path);
    label1 = lv_label_create(obj1);
    lv_obj_set_style_text_font(label1, font_shs_10r, 0);
    lv_obj_set_style_text_color(label1, lv_color_make(208, 207, 212), 0);
    lv_label_set_text(label1, "国内连接");
    domestic_img = img1;

    img2 = lv_img_create(obj1);
    lv_img_set_src(img2, icon1_path);
    label2 = lv_label_create(obj1);
    lv_obj_set_style_text_font(label2, font_shs_10r, 0);
    lv_obj_set_style_text_color(label2, lv_color_make(208, 207, 212), 0);
    lv_label_set_text(label2, "国际连接");
    foreign_img = img2;

    lv_obj_set_grid_cell(img1, LV_GRID_ALIGN_CENTER, 0, 1, LV_GRID_ALIGN_CENTER, 0, 1);
    lv_obj_set_grid_cell(label1, LV_GRID_ALIGN_START, 1, 1, LV_GRID_ALIGN_CENTER, 0, 1);
    lv_obj_set_grid_cell(img2, LV_GRID_ALIGN_CENTER, 3, 1, LV_GRID_ALIGN_CENTER, 0, 1);
    lv_obj_set_grid_cell(label2, LV_GRID_ALIGN_START, 4, 1, LV_GRID_ALIGN_CENTER, 0, 1);


// ------------------------ col 0 row 1 -----------------------------
    static lv_coord_t col_dsc2[] = {LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};
    static lv_coord_t row_dsc2[] = {LV_GRID_FR(50), LV_GRID_FR(72), LV_GRID_TEMPLATE_LAST};

    lv_obj_set_style_border_width(son_obj[1], 0, 0);
    lv_obj_set_style_bg_color(son_obj[1], lv_color_black(), 0);
    lv_obj_set_grid_dsc_array(son_obj[1], col_dsc2, row_dsc2);
    lv_obj_set_style_pad_all(son_obj[1], 0, 0);   // 容器上下左右边界
    lv_obj_set_style_pad_gap(son_obj[1], 6, 0);   // 容器子对象间隔


    lv_obj_t *son_x1y0_s0 = lv_obj_create(son_obj[1]);
    lv_obj_set_grid_cell(son_x1y0_s0, LV_GRID_ALIGN_STRETCH, 0, 1,
                            LV_GRID_ALIGN_STRETCH, 0, 1);
    lv_obj_clear_flag(son_x1y0_s0, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_style_pad_all(son_x1y0_s0, 0, 0);
    lv_obj_set_style_bg_color(son_x1y0_s0, lv_color_make(20, 17, 39), 0);
    lv_obj_set_style_radius(son_x1y0_s0, 0, 0);
    lv_obj_set_style_border_color(son_x1y0_s0, lv_color_make(20, 17, 39), 0);

    static lv_coord_t col_dsc9[] = {LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};
    static lv_coord_t row_dsc9[] = {LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};
    lv_obj_set_grid_dsc_array(son_x1y0_s0, col_dsc9, row_dsc9);

    lv_obj_t * panel1 = lv_obj_create(son_x1y0_s0);
    lv_obj_set_size(panel1, LV_PCT(50), LV_PCT(100));
    lv_obj_clear_flag(panel1, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_style_bg_opa(panel1, 0, 0);
    lv_obj_set_style_border_width(panel1, 0, 0);
    lv_obj_set_style_pad_hor(panel1, 10, 0);
    lv_obj_set_style_pad_ver(panel1, 10, 0);
    lv_obj_set_style_pad_row(panel1, 2, 0);
    lv_obj_set_style_pad_column(panel1, 10, 0);
    lv_obj_set_style_radius(panel1, 0, 0);
    lv_obj_t * panel2 = lv_obj_create(son_x1y0_s0);
    lv_obj_set_size(panel2, LV_PCT(50), LV_PCT(100));
    lv_obj_clear_flag(panel2, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_style_bg_opa(panel2, 0, 0);
    lv_obj_set_style_border_width(panel2, 0, 0);
    lv_obj_set_style_pad_hor(panel2, 10, 0);
    lv_obj_set_style_pad_ver(panel2, 10, 0);
    lv_obj_set_style_pad_row(panel2, 2, 0);
    lv_obj_set_style_pad_column(panel2, 10, 0);
    lv_obj_set_style_radius(panel2, 0, 0);
    // lv_obj_add_flag(panel2, LV_OBJ_FLAG_CLICKABLE);
    // lv_obj_add_event_cb(panel2, click_load_scr_event_cb, LV_EVENT_CLICKED, &info_sid);
    lv_obj_set_grid_cell(panel1, LV_GRID_ALIGN_CENTER, 0, 1, LV_GRID_ALIGN_CENTER, 0, 1);
    lv_obj_set_grid_cell(panel2, LV_GRID_ALIGN_CENTER, 1, 1, LV_GRID_ALIGN_CENTER, 0, 1);

    static lv_coord_t col_dsc10[] = {LV_GRID_CONTENT, LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};
    static lv_coord_t row_dsc10[] = {LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};
    lv_obj_set_grid_dsc_array(panel1, col_dsc10, row_dsc10);
    lv_obj_set_grid_dsc_array(panel2, col_dsc10, row_dsc10);

    label1 = lv_label_create(panel1);
    lv_obj_set_style_text_font(label1, font_shs_10b, 0);
    lv_obj_set_style_text_color(label1, red_color, 0);
    lv_label_set_text(label1, "x");
    link_label = label1;

    img1 = lv_img_create(panel1);
    lv_img_set_src(img1, icon2_path);
    label1 = lv_label_create(panel1);
    lv_obj_set_style_text_font(label1, font_shs_12b, 0);
    lv_obj_set_style_text_color(label1, lv_color_white(), 0);
    lv_label_set_text(label1, "未知");
    linkstatus_label = label1;
    label2 = lv_label_create(panel1);
    lv_obj_set_style_text_font(label2, font_shs_10r, 0);
    lv_obj_set_style_text_color(label2, lv_color_white(), 0);
    lv_label_set_text(label2, "0小时0分0秒");
    lv_obj_set_grid_cell(img1, LV_GRID_ALIGN_START, 0, 1, LV_GRID_ALIGN_CENTER, 0, 2);
    lv_obj_set_grid_cell(label1, LV_GRID_ALIGN_START, 1, 1, LV_GRID_ALIGN_END, 0, 1);
    lv_obj_set_grid_cell(label2, LV_GRID_ALIGN_START, 1, 1, LV_GRID_ALIGN_START, 1, 1);
    link_img = img1;
    up_label = label2;

    img1 = lv_img_create(panel2);
    lv_img_set_src(img1, icon3_path);
    label1 = lv_label_create(panel2);
    lv_obj_set_style_text_font(label1, font_shs_12b, 0);
    lv_obj_set_style_text_color(label1, lv_color_white(), 0);
    lv_label_set_text(label1, "0");
    label2 = lv_label_create(panel2);
    lv_obj_set_style_text_font(label2, font_shs_10r, 0);
    lv_obj_set_style_text_color(label2, lv_color_white(), 0);
    lv_label_set_text(label2, "已连接设备");
    lv_obj_set_grid_cell(img1, LV_GRID_ALIGN_START, 0, 1, LV_GRID_ALIGN_CENTER, 0, 2);
    lv_obj_set_grid_cell(label1, LV_GRID_ALIGN_START, 1, 1, LV_GRID_ALIGN_END, 0, 1);
    lv_obj_set_grid_cell(label2, LV_GRID_ALIGN_START, 1, 1, LV_GRID_ALIGN_START, 1, 1);
    devices_label = label1;

    lv_obj_t *son_x1y0_s1 = lv_obj_create(son_obj[1]);
    lv_obj_set_grid_cell(son_x1y0_s1, LV_GRID_ALIGN_STRETCH, 0, 1,
                            LV_GRID_ALIGN_STRETCH, 1, 1);
    lv_obj_clear_flag(son_x1y0_s1, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_style_pad_all(son_x1y0_s1, 0, 0);
    lv_obj_set_style_bg_color(son_x1y0_s1, lv_color_make(20, 17, 39), 0);
    lv_obj_set_style_radius(son_x1y0_s1, 0, 0);
    lv_obj_set_style_border_color(son_x1y0_s1, lv_color_make(255, 187, 50), 0);

    obj = lv_obj_create(son_x1y0_s1);
    lv_obj_set_style_radius(obj, 0, 0);
    lv_obj_set_style_bg_color(obj, lv_color_make(255, 187, 50), 0);
    lv_obj_set_style_border_width(obj, 0, 0);
    lv_obj_set_style_pad_all(obj, 5, 0);
    lv_obj_set_size(obj, LV_PCT(100), LV_PCT(32));
    lv_obj_clear_flag(obj, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_align(obj, LV_ALIGN_TOP_MID, 0, 0);

    label1 = lv_label_create(obj);
    lv_obj_set_style_text_font(label1, font_shs_10b, 0);
    lv_obj_set_style_text_color(label1, lv_color_black(), 0);
    lv_label_set_text(label1, "IP地址");
    lv_obj_align(label1, LV_ALIGN_LEFT_MID, 0, 0);

    obj = lv_obj_create(son_x1y0_s1);
    lv_obj_set_style_radius(obj, 0, 0);
    // lv_obj_set_style_bg_color(obj, lv_color_make(128, 255, 128), 0);
    lv_obj_set_style_bg_opa(obj, 0, 0);
    lv_obj_set_style_border_width(obj, 0, 0);
    lv_obj_set_style_pad_all(obj, 0, 0);
    lv_obj_set_size(obj, LV_PCT(100), LV_PCT(68));
    lv_obj_clear_flag(obj, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_align(obj, LV_ALIGN_BOTTOM_MID, 0, 0);

    static lv_coord_t col_dsc6[] = {LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};
    static lv_coord_t row_dsc6[] = {LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};
    lv_obj_set_grid_dsc_array(obj, col_dsc6, row_dsc6);
    lv_obj_set_style_pad_all(obj, 10, 0);

    label1 = lv_label_create(obj);
    lv_obj_set_style_text_font(label1, font_shs_10r, 0);
    lv_obj_set_style_text_color(label1, lv_color_white(), 0);
    lv_label_set_text(label1, "IPv4: ");
    ipv4_label = label1;

    label2 = lv_label_create(obj);
    lv_obj_set_style_text_font(label2, font_shs_10r, 0);
    lv_obj_set_style_text_color(label2, lv_color_white(), 0);
    lv_label_set_text(label2, "DNS: ");
    dns_label = label2;

    label3 = lv_label_create(obj);
    lv_obj_set_style_text_font(label3, font_shs_10r, 0);
    lv_obj_set_style_text_color(label3, lv_color_white(), 0);
    lv_label_set_text(label3, "IPv6: ");
    ipv6_label = label3;

    lv_obj_set_grid_cell(label1, LV_GRID_ALIGN_START, 0, 1, LV_GRID_ALIGN_CENTER, 0, 1);
    lv_obj_set_grid_cell(label2, LV_GRID_ALIGN_START, 1, 1, LV_GRID_ALIGN_CENTER, 0, 1);
    lv_obj_set_grid_cell(label3, LV_GRID_ALIGN_START, 0, 2, LV_GRID_ALIGN_CENTER, 1, 1);

// ------------------------ col 1 row 1 create -----------------------------
    static lv_coord_t col_dsc5[] = {LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};
    static lv_coord_t row_dsc5[] = {LV_GRID_CONTENT, LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};

    lv_obj_set_grid_dsc_array(son_obj[3], col_dsc5, row_dsc5);
    lv_obj_set_style_pad_all(son_obj[3], 5, 0);
    lv_obj_set_style_pad_row(son_obj[3], 10, 0);
    lv_obj_set_style_pad_column(son_obj[3], 5, 0);

    lv_obj_t *son_obj3_label1 = lv_label_create(son_obj[3]);
    lv_obj_set_style_text_font(son_obj3_label1, font_shs_12b, 0);
    lv_obj_set_style_text_color(son_obj3_label1, lv_color_white(), 0);
    lv_label_set_text(son_obj3_label1, "CPU");

    lv_obj_t *son_obj3_label2 = lv_label_create(son_obj[3]);
    lv_obj_set_style_text_font(son_obj3_label2, font_shs_12b, 0);
    lv_obj_set_style_text_color(son_obj3_label2, lv_color_white(), 0);
    lv_label_set_text(son_obj3_label2, "温度");
    
    lv_obj_t *cont1 = lv_obj_create(son_obj[3]);
    lv_obj_clear_flag(cont1, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_style_bg_opa(cont1, 0, 0);
    lv_obj_set_style_border_width(cont1, 0, 0);
    lv_obj_set_size(cont1, LV_PCT(50), LV_PCT(90));

    lv_obj_t *cont2 = lv_obj_create(son_obj[3]);
    lv_obj_clear_flag(cont2, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_style_bg_opa(cont2, 0, 0);
    lv_obj_set_style_border_width(cont2, 0, 0);
    lv_obj_set_size(cont2, LV_PCT(50), LV_PCT(90));
    
    lv_obj_update_layout(cont1);
    int arc_size = (lv_obj_get_width(cont1) < lv_obj_get_height(cont1) ? lv_obj_get_width(cont1) : lv_obj_get_height(cont1)) - 5;
    arc1 = lv_arc_create(cont1);
    lv_obj_clear_flag(arc1, LV_OBJ_FLAG_IGNORE_LAYOUT);
    lv_arc_set_rotation(arc1, 270);
    lv_arc_set_bg_angles(arc1, 0, 360);
    lv_obj_remove_style(arc1, NULL, LV_PART_KNOB);   /*Be sure the knob is not displayed*/
    lv_obj_clear_flag(arc1, LV_OBJ_FLAG_CLICKABLE);  /*To not allow adjusting by click*/
    lv_obj_set_size(arc1, arc_size, arc_size);
    lv_obj_center(arc1);
    lv_arc_set_mode(arc1, LV_ARC_MODE_REVERSE);
    lv_arc_set_value(arc1, 100);
    lv_obj_set_style_arc_width(arc1, arc_size / 10, 0);
    lv_obj_set_style_arc_width(arc1, arc_size / 10, LV_PART_INDICATOR);
    lv_obj_set_style_arc_color(arc1, lv_color_make(224, 224, 224), 0);
    lv_obj_set_style_arc_color(arc1, lv_color_make(248, 156, 44), LV_PART_INDICATOR);
    // lv_obj_set_style_bg_color(arc1, lv_color_make(255, 0, 0), 0);
    // lv_obj_set_style_bg_opa(arc1, 255, 0);
    // lv_obj_set_style_radius(arc1, LV_RADIUS_CIRCLE, 0);
    cpu_arc = arc1;

    arc2 = lv_arc_create(cont2);
    lv_obj_clear_flag(arc2, LV_OBJ_FLAG_IGNORE_LAYOUT);
    lv_arc_set_rotation(arc2, 270);
    lv_arc_set_bg_angles(arc2, 0, 360);
    lv_obj_remove_style(arc2, NULL, LV_PART_KNOB);   /*Be sure the knob is not displayed*/
    lv_obj_clear_flag(arc2, LV_OBJ_FLAG_CLICKABLE);  /*To not allow adjusting by click*/
    lv_obj_set_size(arc2, arc_size, arc_size);
    lv_obj_center(arc2);
    lv_arc_set_mode(arc2, LV_ARC_MODE_REVERSE);
    lv_arc_set_value(arc2, 100);
    lv_obj_set_style_arc_width(arc2, arc_size / 10, 0);
    lv_obj_set_style_arc_width(arc2, arc_size / 10, LV_PART_INDICATOR);
    lv_obj_set_style_arc_color(arc2, lv_color_make(224, 224, 224), 0);
    lv_obj_set_style_arc_color(arc2, lv_color_make(55, 194, 141), LV_PART_INDICATOR);
    temp_arc = arc2;

    lv_obj_t *cont3 = lv_obj_create(arc1);
    lv_obj_clear_flag(cont3, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_style_bg_color(cont3, lv_color_make(41, 41, 41), 0);
    lv_obj_set_style_border_width(cont3, 0, 0);
    lv_obj_set_style_radius(cont3, LV_RADIUS_CIRCLE, 0);
    lv_obj_set_size(cont3, LV_PCT(70), LV_PCT(70));
    lv_obj_center(cont3);
    
    lv_obj_t *cont4 = lv_obj_create(arc2);
    lv_obj_clear_flag(cont4, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_style_bg_color(cont4, lv_color_make(41, 41, 41), 0);
    lv_obj_set_style_border_width(cont4, 0, 0);
    lv_obj_set_style_radius(cont4, LV_RADIUS_CIRCLE, 0);
    lv_obj_set_size(cont4, LV_PCT(70), LV_PCT(70));
    lv_obj_center(cont4);

    label1 = lv_label_create(arc1);
    lv_obj_set_style_text_font(label1, font_shs_16b, 0);
    lv_obj_set_style_text_color(label1, lv_color_white(), 0);
    lv_label_set_text(label1, "-");
    lv_obj_center(label1);
    cpu_label = label1;

    label2 = lv_label_create(arc2);
    lv_obj_set_style_text_font(label2, font_shs_16b, 0);
    lv_obj_set_style_text_color(label2, lv_color_white(), 0);
    lv_label_set_text(label2, "-");
    lv_obj_center(label2);
    temp_label = label2;

    lv_obj_set_grid_cell(son_obj3_label1, LV_GRID_ALIGN_CENTER, 0, 1, LV_GRID_ALIGN_CENTER, 0, 1);
    lv_obj_set_grid_cell(son_obj3_label2, LV_GRID_ALIGN_CENTER, 1, 1, LV_GRID_ALIGN_CENTER, 0, 1);
    lv_obj_set_grid_cell(cont1, LV_GRID_ALIGN_START, 0, 1, LV_GRID_ALIGN_CENTER, 1, 1);
    lv_obj_set_grid_cell(cont2, LV_GRID_ALIGN_START, 1, 1, LV_GRID_ALIGN_CENTER, 1, 1);

// ------------------------ col 1 row 1 end -----------------------------

// ------------------------ col 1 row 2 create -----------------------------
    static lv_coord_t col_dsc3[] = {LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};
    static lv_coord_t row_dsc3[] = {LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};

    lv_obj_set_style_border_width(son_obj[4], 0, 0);
    lv_obj_set_style_bg_color(son_obj[4], lv_color_black(), 0);
    lv_obj_set_grid_dsc_array(son_obj[4], col_dsc3, row_dsc3);
    lv_obj_set_style_pad_all(son_obj[4], 0, 0);   // 容器上下左右边界
    lv_obj_set_style_pad_gap(son_obj[4], 6, 0);   // 容器子对象间隔

    lv_obj_t *son_x2y1_s0 = lv_obj_create(son_obj[4]);
    lv_obj_set_grid_cell(son_x2y1_s0, LV_GRID_ALIGN_STRETCH, 0, 1,
                            LV_GRID_ALIGN_STRETCH, 0, 1);
    lv_obj_clear_flag(son_x2y1_s0, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_style_bg_color(son_x2y1_s0, lv_color_make(20, 17, 39), 0);
    lv_obj_set_style_radius(son_x2y1_s0, 0, 0);
    lv_obj_set_style_border_color(son_x2y1_s0, lv_color_make(20, 17, 39), 0);
    lv_obj_set_style_pad_all(son_x2y1_s0, 2, 0);
    lv_obj_set_style_pad_gap(son_x2y1_s0, 0, 0);

    lv_obj_t *son_x2y1_s1 = lv_obj_create(son_obj[4]);
    lv_obj_set_grid_cell(son_x2y1_s1, LV_GRID_ALIGN_STRETCH, 0, 1,
                            LV_GRID_ALIGN_STRETCH, 1, 1);
    lv_obj_clear_flag(son_x2y1_s1, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_style_bg_color(son_x2y1_s1, lv_color_make(20, 17, 39), 0);
    lv_obj_set_style_radius(son_x2y1_s1, 0, 0);
    lv_obj_set_style_border_color(son_x2y1_s1, lv_color_make(20, 17, 39), 0);
    lv_obj_set_style_pad_all(son_x2y1_s1, 2, 0);
    lv_obj_set_style_pad_gap(son_x2y1_s1, 0, 0);

    lv_obj_t *son_x2y1_s2 = lv_obj_create(son_obj[4]);
    lv_obj_set_grid_cell(son_x2y1_s2, LV_GRID_ALIGN_STRETCH, 0, 1,
                            LV_GRID_ALIGN_STRETCH, 2, 1);
    lv_obj_clear_flag(son_x2y1_s2, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_style_pad_all(son_x2y1_s2, 0, 0);
    lv_obj_set_style_bg_color(son_x2y1_s2, lv_color_make(20, 17, 39), 0);
    lv_obj_set_style_radius(son_x2y1_s2, 0, 0);
    lv_obj_set_style_border_color(son_x2y1_s2, lv_color_make(20, 17, 39), 0);
    lv_obj_set_style_pad_all(son_x2y1_s2, 2, 0);
    lv_obj_set_style_pad_gap(son_x2y1_s2, 0, 0);

    lv_obj_t * son_x2y1_s0_label1 = lv_label_create(son_x2y1_s0);
    lv_obj_set_style_text_font(son_x2y1_s0_label1, font_shs_10r, 0);
    lv_obj_set_style_text_color(son_x2y1_s0_label1, lv_color_make(184, 184, 190), 0);
    lv_label_set_text(son_x2y1_s0_label1, "硬盘1:");
    disk_labels[0].name = son_x2y1_s0_label1;

    lv_obj_t * son_x2y1_s0_bar1 = lv_bar_create(son_x2y1_s0);
    lv_obj_set_size(son_x2y1_s0_bar1, LV_PCT(100), LV_PCT(80));
    lv_obj_set_style_bg_color(son_x2y1_s0_bar1, lv_color_make(84, 216, 167), LV_PART_INDICATOR);
    lv_obj_set_style_bg_color(son_x2y1_s0_bar1, lv_color_make(64, 64, 64), 0);
    lv_obj_set_style_radius(son_x2y1_s0_bar1, 0, 0);
    lv_obj_set_style_radius(son_x2y1_s0_bar1, 0, LV_PART_INDICATOR);
    lv_obj_clear_flag(son_x2y1_s0_bar1, LV_OBJ_FLAG_IGNORE_LAYOUT);
    lv_bar_set_value(son_x2y1_s0_bar1, 0, LV_ANIM_OFF);
    disk_labels[0].bar = son_x2y1_s0_bar1;

    lv_obj_t * son_x2y1_s0_label2 = lv_label_create(son_x2y1_s0);
    lv_obj_set_style_text_font(son_x2y1_s0_label2, font_shs_10r, 0);
    lv_obj_set_style_text_color(son_x2y1_s0_label2, lv_color_white(), 0);
    lv_label_set_text(son_x2y1_s0_label2, "---/---");
    disk_labels[0].used = son_x2y1_s0_label2;

    lv_obj_t * son_x2y1_s1_label1 = lv_label_create(son_x2y1_s1);
    lv_obj_set_style_text_font(son_x2y1_s1_label1, font_shs_10r, 0);
    lv_obj_set_style_text_color(son_x2y1_s1_label1, lv_color_make(184, 184, 190), 0);
    lv_label_set_text(son_x2y1_s1_label1, "硬盘2:");
    disk_labels[1].name = son_x2y1_s1_label1;

    lv_obj_t * son_x2y1_s1_bar1 = lv_bar_create(son_x2y1_s1);
    lv_obj_set_size(son_x2y1_s1_bar1, LV_PCT(100), LV_PCT(80));
    lv_obj_set_style_bg_color(son_x2y1_s1_bar1, lv_color_make(250, 185, 90), LV_PART_INDICATOR);
    lv_obj_set_style_bg_color(son_x2y1_s1_bar1, lv_color_make(64, 64, 64), 0);
    lv_obj_set_style_radius(son_x2y1_s1_bar1, 0, 0);
    lv_obj_set_style_radius(son_x2y1_s1_bar1, 0, LV_PART_INDICATOR);
    lv_obj_clear_flag(son_x2y1_s1_bar1, LV_OBJ_FLAG_IGNORE_LAYOUT);
    lv_bar_set_value(son_x2y1_s1_bar1, 0, LV_ANIM_OFF);
    disk_labels[1].bar = son_x2y1_s1_bar1;

    lv_obj_t * son_x2y1_s1_label2 = lv_label_create(son_x2y1_s1);
    lv_obj_set_style_text_font(son_x2y1_s1_label2, font_shs_10r, 0);
    lv_obj_set_style_text_color(son_x2y1_s1_label2, lv_color_white(), 0);
    lv_label_set_text(son_x2y1_s1_label2, "---/---");
    disk_labels[1].used = son_x2y1_s1_label2;

    lv_obj_t * son_x2y1_s2_label1 = lv_label_create(son_x2y1_s2);
    lv_obj_set_style_text_font(son_x2y1_s2_label1, font_shs_10r, 0);
    lv_obj_set_style_text_color(son_x2y1_s2_label1, lv_color_make(184, 184, 190), 0);
    lv_label_set_text(son_x2y1_s2_label1, "硬盘3:");
    disk_labels[2].name = son_x2y1_s2_label1;

    lv_obj_t * son_x2y1_s2_bar1 = lv_bar_create(son_x2y1_s2);
    lv_obj_set_size(son_x2y1_s2_bar1, LV_PCT(100), LV_PCT(80));
    lv_obj_set_style_bg_color(son_x2y1_s2_bar1, lv_color_make(185, 250, 90), LV_PART_INDICATOR);
    lv_obj_set_style_bg_color(son_x2y1_s2_bar1, lv_color_make(64, 64, 64), 0);
    lv_obj_set_style_radius(son_x2y1_s2_bar1, 0, 0);
    lv_obj_set_style_radius(son_x2y1_s2_bar1, 0, LV_PART_INDICATOR);
    lv_obj_clear_flag(son_x2y1_s2_bar1, LV_OBJ_FLAG_IGNORE_LAYOUT);
    lv_bar_set_value(son_x2y1_s2_bar1, 0, LV_ANIM_OFF);
    disk_labels[2].bar = son_x2y1_s2_bar1;

    lv_obj_t * son_x2y1_s2_label2 = lv_label_create(son_x2y1_s2);
    lv_obj_set_style_text_font(son_x2y1_s2_label2, font_shs_10r, 0);
    lv_obj_set_style_text_color(son_x2y1_s2_label2, lv_color_white(), 0);
    lv_label_set_text(son_x2y1_s2_label2, "---/---");
    disk_labels[2].used = son_x2y1_s2_label2;

    static lv_coord_t col_dsc4[] = {LV_GRID_FR(1), LV_GRID_CONTENT, LV_GRID_TEMPLATE_LAST};
    static lv_coord_t row_dsc4[] = {LV_GRID_CONTENT, LV_GRID_CONTENT, LV_GRID_TEMPLATE_LAST};
    lv_obj_set_grid_dsc_array(son_x2y1_s0, col_dsc4, row_dsc4);
    lv_obj_set_grid_dsc_array(son_x2y1_s1, col_dsc4, row_dsc4);
    lv_obj_set_grid_dsc_array(son_x2y1_s2, col_dsc4, row_dsc4);
    lv_obj_set_grid_cell(son_x2y1_s0_label1, LV_GRID_ALIGN_START, 0, 1, LV_GRID_ALIGN_SPACE_EVENLY, 0, 1);
    lv_obj_set_grid_cell(son_x2y1_s0_label2, LV_GRID_ALIGN_END, 1, 1, LV_GRID_ALIGN_SPACE_EVENLY, 0, 1);
    lv_obj_set_grid_cell(son_x2y1_s0_bar1, LV_GRID_ALIGN_CENTER, 0, 2, LV_GRID_ALIGN_SPACE_EVENLY, 1, 1);
    lv_obj_set_grid_cell(son_x2y1_s1_label1, LV_GRID_ALIGN_START, 0, 1, LV_GRID_ALIGN_SPACE_EVENLY, 0, 1);
    lv_obj_set_grid_cell(son_x2y1_s1_label2, LV_GRID_ALIGN_END, 1, 1, LV_GRID_ALIGN_SPACE_EVENLY, 0, 1);
    lv_obj_set_grid_cell(son_x2y1_s1_bar1, LV_GRID_ALIGN_CENTER, 0, 2, LV_GRID_ALIGN_SPACE_EVENLY, 1, 1);
    lv_obj_set_grid_cell(son_x2y1_s2_label1, LV_GRID_ALIGN_START, 0, 1, LV_GRID_ALIGN_SPACE_EVENLY, 0, 1);
    lv_obj_set_grid_cell(son_x2y1_s2_label2, LV_GRID_ALIGN_END, 1, 1, LV_GRID_ALIGN_SPACE_EVENLY, 0, 1);
    lv_obj_set_grid_cell(son_x2y1_s2_bar1, LV_GRID_ALIGN_CENTER, 0, 2, LV_GRID_ALIGN_SPACE_EVENLY, 1, 1);

// ------------------------ col 1 row 2 end -----------------------------


    SCR_FUNC_TYPE *_user_data = malloc(sizeof(SCR_FUNC_TYPE));
    _user_data->load_func = home_scr_load_func;
    _user_data->refr_func = home_scr_refr_func;
    _user_data->quit_func = home_scr_quit_func;

    scr_add_user_data(home_scr, E_HOME_SCR, _user_data);
}

static void get_date(char* date, char* time);
void home_scr_update(void)
{
  char buf[256];
  char date_str[16], time_str[16];
  disk_info_t *disk;
  disk_label_t *disk_label;
  int i;
  monitor_info_t *info = get_monitor_info();
  lv_obj_add_flag(link_img, LV_OBJ_FLAG_HIDDEN);
  lv_obj_add_flag(domestic_img, LV_OBJ_FLAG_HIDDEN);
  lv_obj_add_flag(foreign_img, LV_OBJ_FLAG_HIDDEN);
  lv_obj_add_flag(link_label, LV_OBJ_FLAG_HIDDEN);
  lv_obj_add_flag(domestic_label, LV_OBJ_FLAG_HIDDEN);
  lv_obj_add_flag(foreign_label, LV_OBJ_FLAG_HIDDEN);

  if (!info->docker_ok) {
    lv_label_set_text(err_label, "Docker未运行");
  } else if (!info->linkease_ok) {
    lv_label_set_text(err_label, "易有云未运行");
  } else {
    lv_label_set_text(err_label, "iStoreOS");
  }

  get_date(date_str, time_str);
  lv_label_set_text(date_label, date_str);
  lv_label_set_text(time_label, time_str);

  if ('\0' == info->net_err[0]) {
    lv_obj_clear_flag(link_img, LV_OBJ_FLAG_HIDDEN);
    lv_obj_set_grid_cell(link_img, LV_GRID_ALIGN_START, 0, 1, LV_GRID_ALIGN_CENTER, 0, 2);
    lv_label_set_text(linkstatus_label, "已联网");

    lv_obj_clear_flag(domestic_img, LV_OBJ_FLAG_HIDDEN);
    lv_obj_set_grid_cell(domestic_img, LV_GRID_ALIGN_CENTER, 0, 1, LV_GRID_ALIGN_CENTER, 0, 1);
  } else {
    lv_obj_clear_flag(link_label, LV_OBJ_FLAG_HIDDEN);
    lv_obj_set_grid_cell(link_label, LV_GRID_ALIGN_START, 0, 1, LV_GRID_ALIGN_CENTER, 0, 2);
    lv_label_set_text(linkstatus_label, info->net_err);

    lv_obj_clear_flag(domestic_label, LV_OBJ_FLAG_HIDDEN);
    lv_obj_set_grid_cell(domestic_label, LV_GRID_ALIGN_CENTER, 0, 1, LV_GRID_ALIGN_CENTER, 0, 1);
  }

  if (0 == info->foreign_link) {
    lv_obj_clear_flag(foreign_label, LV_OBJ_FLAG_HIDDEN);
    lv_obj_set_grid_cell(foreign_label, LV_GRID_ALIGN_CENTER, 3, 1, LV_GRID_ALIGN_CENTER, 0, 1);
  } else {
    lv_obj_clear_flag(foreign_img, LV_OBJ_FLAG_HIDDEN);
    lv_obj_set_grid_cell(foreign_img, LV_GRID_ALIGN_CENTER, 3, 1, LV_GRID_ALIGN_CENTER, 0, 1);
  }

  sprintf(buf, "%d", info->devices);
  lv_label_set_text(devices_label, buf);

  sprintf(buf, "IPv4: %s", info->ipv4);
  lv_label_set_text(ipv4_label, buf);

  sprintf(buf, "IPv6: %s", info->ipv6);
  lv_label_set_text(ipv6_label, buf);

  sprintf(buf, "DNS: %s", info->dns);
  lv_label_set_text(dns_label, buf);

  lv_label_set_text(up_label, info->uptime_human);
  lv_label_set_text(public_ipv4_label, info->public_ipv4);

  sprintf(buf, "%d%%", info->cpu);
  lv_label_set_text(cpu_label, buf);
  lv_arc_set_value(cpu_arc, 100-info->cpu);

  sprintf(buf, "%d℃", info->temperature);
  lv_label_set_text(temp_label, buf);
  if (info->temperature > 200) {
    i = 100;
  } else if (info->temperature > 100) {
    i = 90+(info->temperature-90)*10/100;
  } else {
    i = info->temperature;
  }
  lv_arc_set_value(temp_arc, 100-i);

  sprintf(buf, "%s/s", info->upload_str);
  lv_label_set_text(upload_label, buf);
  sprintf(buf, "%s/s", info->download_str);
  lv_label_set_text(download_label, buf);

  for(i = 0; i < 3; i++) {
    disk = &info->disks[i];
    disk_label = &disk_labels[i];
    if (disk->used_percent >= 0) {
      sprintf(buf, "%s:", disk->name);
      lv_label_set_text(disk_label->name, buf);
      sprintf(buf, "%s/%s", disk->used, disk->total);
      lv_label_set_text(disk_label->used, buf);
      lv_bar_set_value(disk_label->bar, disk->used_percent, LV_ANIM_OFF);
      if (disk->used_percent < 60) { 
        lv_obj_set_style_bg_color(disk_label->bar, lv_color_make(84, 216, 167), LV_PART_INDICATOR); 
      } else { 
        lv_obj_set_style_bg_color(disk_label->bar, lv_color_make(250, 185, 90), LV_PART_INDICATOR);
      }
    } else {
      sprintf(buf, "硬盘%d:", i+1);
      lv_label_set_text(disk_label->used, "---/---");
      lv_bar_set_value(disk_label->bar, 0, LV_ANIM_OFF); 
      lv_obj_set_style_bg_color(disk_label->bar, lv_color_make(185, 250, 90), LV_PART_INDICATOR);
    }
  }
}

static void get_date(char* date_str, char* time_str)
{
    time_t now = time(NULL);
    now += 8*3600; // // 加上 8 小时
    //struct tm *local = localtime(&now);
    struct tm *utc_time = gmtime(&now);

    strftime(date_str, 16, "%Y-%m-%d", utc_time);
    strftime(time_str, 16, "%H:%M", utc_time);
}
