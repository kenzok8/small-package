#include "ui_common.h"

static lv_obj_t *info_scr;
static int refr_lock = 1;

lv_obj_t *info_table1;
lv_obj_t *info_table2;

static void info_scr_obj_create(void);
static void info_scr_obj_delete(void);

static void draw_part_event_cb(lv_event_t * e)
{
    lv_event_code_t code = lv_event_get_code(e);
    lv_obj_t * obj = lv_event_get_target(e);
    lv_obj_draw_part_dsc_t * dsc = lv_event_get_draw_part_dsc(e);
    /*If the cells are drawn...*/
    if(code == LV_EVENT_DRAW_PART_BEGIN) {
        if(dsc->part == LV_PART_ITEMS) {
            uint32_t row = dsc->id /  lv_table_get_col_cnt(obj);
            uint32_t col = dsc->id - row * lv_table_get_col_cnt(obj);

            /*Make the texts in the first cell center aligned*/
            if(row == 0) {
                dsc->label_dsc->color = lv_color_make(178, 178, 178);
                dsc->rect_dsc->bg_color = lv_color_black();
            }

            if(col == 0) {
                dsc->label_dsc->align = LV_TEXT_ALIGN_LEFT;
            }

            /*MAke every 2nd row grayish*/
            if(row != 0) {
                dsc->label_dsc->color = lv_color_white();
                dsc->rect_dsc->bg_color = lv_color_black();
            }
        }
    }
}

static void change_event_cb(lv_event_t * e)
{
    lv_obj_t * obj = lv_event_get_target(e);
    lv_point_t point_read;
    uint16_t col;
    uint16_t row;
    lv_table_get_selected_cell(obj, &row, &col);
    lv_indev_get_point(lv_indev_get_act(), &point_read);
    printf("row: %d col: %d x: %d y: %d\n", row, col, point_read.x, point_read.y);
}

static void info_scr_load_func(void *arg)
{
    // ... ui_init
    info_scr_obj_create();
    refr_lock = 0;
}


void clear_info_table(void)
{
    lv_table_set_row_cnt(info_table1, 1);
    lv_table_set_row_cnt(info_table2, 1);
}

void update_info_table(void)
{
    const char *str1[][4] = {
        {"GIFA", "192.168.9.90", "50:62:32:09:FA:A2", "Wifi"},
        {"52:5B:09:B1:51:C7", "192.168.9.90", "50:62:32:09:FA:A2", "LAN1"},
        {"GIFA-TECHNOLOGY...", "192.168.9.90", "50:62:32:09:FA:A2", "LAN2"},
        {"GIFA", "192.168.9.90", "50:62:32:09:FA:A2", "Wifi"},
        {"52:5B:09:B1:51:C7", "192.168.9.90", "50:62:32:09:FA:A2", "LAN1"},
        {"GIFA-TECHNOLOGY...", "192.168.9.90", "50:62:32:09:FA:A2", "LAN2"},
        {"GIFA-TECHNOLOGY...", "192.168.9.90", "50:62:32:09:FA:A2", "LAN2"},
        {"GIFA-TECHNOLOGY...", "192.168.9.90", "50:62:32:09:FA:A2", "LAN2"},
        {"GIFA-TECHNOLOGY...", "192.168.9.90", "50:62:32:09:FA:A2", "LAN2"},
        {"GIFA-TECHNOLOGY...", "192.168.9.90", "50:62:32:09:FA:A2", "LAN2"},
    };
    for (int i = 1; i < 10; i++)
    {
        lv_table_set_cell_value(info_table1, i, 0, str1[i - 1][0]);
        lv_table_set_cell_value(info_table1, i, 1, str1[i - 1][1]);
        lv_table_set_cell_value(info_table1, i, 2, str1[i - 1][2]);
        lv_table_set_cell_value(info_table1, i, 3, str1[i - 1][3]);
    }

    const char *str2[][4] = {
        {"eth0", "1000 Mbit/s", "WAN, WAN6"},
        {"eth1", "已断开", "LAN, PLANB"},
        {"eth2", "已断开", "LAN, PLANB"},
        {"eth3", "已断开", "LAN, PLANB"},
    };
    for (int i = 1; i < 4; i++)
    {
        lv_table_set_cell_value(info_table2, i, 0, str2[i - 1][0]);
        lv_table_set_cell_value(info_table2, i, 1, str2[i - 1][1]);
        lv_table_set_cell_value(info_table2, i, 2, str2[i - 1][2]);
    }

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

static void info_scr_refr_func(Event_Data_t *arg)
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

static void info_scr_quit_func(void *arg)
{
    refr_lock = 1;
    // ... ui_del
    info_scr_obj_delete();
}


static void info_scr_obj_create(void)
{

}

static void info_scr_obj_delete(void)
{

}


void info_scr_create(void)
{
    lv_obj_t *label1;

    info_scr = lv_obj_create(NULL);
    lv_obj_set_style_bg_color(info_scr, lv_color_black(), 0);

    test_area2 = lv_obj_create(info_scr);
    lv_obj_set_style_bg_color(test_area2, lv_color_black(), 0);
    // lv_obj_set_size(test_area2, LV_HOR_RES, LV_VER_RES);
    lv_obj_set_style_border_width(test_area2, 0, 0);
    lv_obj_set_size(test_area2, disp_hor, disp_ver);
    lv_obj_center(test_area2);

    lv_obj_set_style_pad_ver(test_area2, 4, 0);   // 容器上下左右边界
    lv_obj_set_style_pad_hor(test_area2, 6, 0);   // 容器上下左右边界
    lv_obj_set_style_pad_gap(test_area2, 6, 0);   // 容器子对象间隔
    
    label1 = lv_label_create(test_area2);
    lv_obj_set_style_text_font(label1, font_mont_16, 0);
    lv_obj_set_style_text_color(label1, lv_color_white(), 0);
    lv_label_set_text(label1, LV_SYMBOL_LEFT);
    lv_obj_align(label1, LV_ALIGN_TOP_LEFT, 10, LV_PCT(10));
    lv_obj_add_flag(label1, LV_OBJ_FLAG_CLICKABLE);
    lv_obj_set_ext_click_area(label1, 10);
    lv_obj_add_event_cb(label1, click_load_scr_event_cb, LV_EVENT_CLICKED, &home_sid);

    lv_obj_t *tabview;
    tabview = lv_tabview_create(test_area2, LV_DIR_TOP, 30);
    lv_obj_set_size(tabview, LV_PCT(100), LV_PCT(80));
    lv_obj_align(tabview, LV_ALIGN_BOTTOM_MID, 0, 0);
    lv_obj_t *tab1 = lv_tabview_add_tab(tabview, "全部");
    lv_obj_t *tab2 = lv_tabview_add_tab(tabview, "接口");

    // lv_obj_scroll_to_view_recursive(label, LV_ANIM_ON);

    lv_obj_t * tab_btns = lv_tabview_get_tab_btns(tabview);
    lv_obj_remove_style(tab_btns, NULL, LV_PART_ITEMS | LV_STATE_PRESSED);
    lv_obj_remove_style(tab_btns, NULL, LV_STATE_FOCUS_KEY);
    lv_obj_remove_style(tab_btns, NULL, LV_PART_ITEMS | LV_STATE_FOCUS_KEY);
    lv_obj_set_style_bg_color(tab_btns, lv_color_make(255, 187, 50), LV_PART_ITEMS | LV_STATE_CHECKED);
    lv_obj_set_style_bg_color(tab_btns, lv_color_black(), 0);
    lv_obj_set_style_bg_opa(tab_btns, 255, LV_PART_ITEMS | LV_STATE_CHECKED);
    lv_obj_set_style_bg_opa(tab_btns, 255, 0);
    lv_obj_set_style_text_font(tab_btns, font_shs_10b, 0);
    lv_obj_set_style_text_color(tab_btns, lv_color_white(), 0);
    lv_obj_set_style_text_color(tab_btns, lv_color_black(), LV_PART_ITEMS | LV_STATE_CHECKED);
    lv_obj_set_style_border_side(tab_btns, LV_BORDER_SIDE_BOTTOM, LV_PART_ITEMS | LV_STATE_CHECKED);
    lv_obj_set_style_border_width(tab_btns, 0, LV_PART_ITEMS | LV_STATE_CHECKED);
    lv_obj_set_style_border_width(tab_btns, 0, 0);
    lv_obj_set_size(tab_btns, LV_PCT(100), LV_PCT(10));

    lv_obj_clear_flag(lv_tabview_get_content(tabview), LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_set_style_bg_color(lv_tabview_get_content(tabview), lv_color_black(), 0);
    lv_obj_set_style_bg_opa(lv_tabview_get_content(tabview), 255, 0);
    lv_obj_set_style_border_width(lv_tabview_get_content(tabview), 2, 0);
    lv_obj_set_style_border_color(lv_tabview_get_content(tabview), lv_color_make(255, 187, 50), 0);

    lv_obj_set_style_pad_ver(tab1, 3, 0);
    lv_obj_set_style_pad_hor(tab1, 8, 0);
    lv_obj_set_style_pad_ver(tab2, 3, 0);
    lv_obj_set_style_pad_hor(tab2, 8, 0);
    lv_obj_clear_flag(tab1, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_clear_flag(tab2, LV_OBJ_FLAG_SCROLLABLE);
    
    info_table1 = lv_table_create(tab1);
    lv_obj_remove_style(info_table1, NULL, LV_PART_ITEMS | LV_STATE_PRESSED);
    lv_obj_set_style_text_align(info_table1, LV_TEXT_ALIGN_CENTER, 0);
    lv_obj_set_style_text_font(info_table1, font_shs_8b, LV_PART_ITEMS);
    lv_obj_set_style_text_color(info_table1, lv_color_make(237, 204, 150), LV_PART_ITEMS);
    lv_obj_set_style_pad_ver(info_table1, font_shs_8b->line_height, LV_PART_ITEMS);
    //printf("line height: %d\n", font_shs_8b->line_height);
    lv_obj_set_style_pad_gap(info_table1, 0, LV_PART_ITEMS);
    lv_obj_set_style_pad_hor(info_table1, 0, LV_PART_ITEMS);
    lv_obj_set_style_border_side(info_table1, LV_BORDER_SIDE_BOTTOM, LV_PART_ITEMS);
    lv_obj_set_style_border_color(info_table1, lv_color_make(128, 93, 25), LV_PART_ITEMS);
    lv_obj_set_style_border_width(info_table1, 3, LV_PART_ITEMS);
    lv_obj_set_style_border_width(info_table1, 0, 0);
    lv_obj_set_style_bg_opa(info_table1, 0, 0);
    lv_obj_clear_flag(info_table1, LV_OBJ_FLAG_SCROLL_ELASTIC);
    lv_obj_set_scrollbar_mode(info_table1, LV_SCROLLBAR_MODE_OFF);
    // lv_obj_clear_flag(info_table1, LV_OBJ_FLAG_SCROLLABLE);

    lv_table_set_cell_value(info_table1, 0, 0, "客户端名称");
    lv_table_set_cell_value(info_table1, 0, 1, "客户端IP地址");
    lv_table_set_cell_value(info_table1, 0, 2, "客户端MAC地址");
    lv_table_set_cell_value(info_table1, 0, 3, "接口");

    lv_obj_set_size(info_table1, LV_PCT(100), LV_PCT(100));
    lv_obj_update_layout(info_table1);
    lv_table_set_col_width(info_table1, 0, lv_obj_get_width(info_table1) / 4);
    lv_table_set_col_width(info_table1, 1, lv_obj_get_width(info_table1) / 4);
    lv_table_set_col_width(info_table1, 2, lv_obj_get_width(info_table1) / 4);
    lv_table_set_col_width(info_table1, 3, lv_obj_get_width(info_table1) / 4);
    lv_obj_align(info_table1, LV_ALIGN_TOP_MID, 0, 0);

    lv_obj_add_event_cb(info_table1, draw_part_event_cb, LV_EVENT_DRAW_PART_BEGIN, NULL);
    lv_obj_add_event_cb(info_table1, change_event_cb, LV_EVENT_VALUE_CHANGED, NULL);

    
    info_table2 = lv_table_create(tab2);
    lv_obj_remove_style(info_table2, NULL, LV_PART_ITEMS | LV_STATE_PRESSED);
    lv_obj_set_style_text_align(info_table2, LV_TEXT_ALIGN_CENTER, 0);
    lv_obj_set_style_text_font(info_table2, font_shs_8b, LV_PART_ITEMS);
    lv_obj_set_style_text_color(info_table2, lv_color_make(237, 204, 150), LV_PART_ITEMS);
    lv_obj_set_style_pad_ver(info_table2, font_shs_8b->line_height, LV_PART_ITEMS);
    //printf("line height: %d\n", font_shs_8b->line_height);
    lv_obj_set_style_pad_gap(info_table2, 0, LV_PART_ITEMS);
    lv_obj_set_style_pad_hor(info_table2, 0, LV_PART_ITEMS);
    lv_obj_set_style_border_side(info_table2, LV_BORDER_SIDE_BOTTOM, LV_PART_ITEMS);
    lv_obj_set_style_border_color(info_table2, lv_color_make(128, 93, 25), LV_PART_ITEMS);
    lv_obj_set_style_border_width(info_table2, 3, LV_PART_ITEMS);
    lv_obj_set_style_border_width(info_table2, 0, 0);
    lv_obj_set_style_bg_opa(info_table2, 0, 0);
    lv_obj_clear_flag(info_table2, LV_OBJ_FLAG_SCROLL_ELASTIC);
    lv_obj_set_scrollbar_mode(info_table2, LV_SCROLLBAR_MODE_OFF);
    // lv_obj_clear_flag(info_table2, LV_OBJ_FLAG_SCROLLABLE);

    lv_table_set_cell_value(info_table2, 0, 0, "接口");
    lv_table_set_cell_value(info_table2, 0, 1, "状态");
    lv_table_set_cell_value(info_table2, 0, 2, "备注");

    lv_obj_set_size(info_table2, LV_PCT(100), LV_PCT(100));
    lv_obj_update_layout(info_table2);
    lv_table_set_col_width(info_table2, 0, lv_obj_get_width(info_table2) / 3);
    lv_table_set_col_width(info_table2, 1, lv_obj_get_width(info_table2) / 3);
    lv_table_set_col_width(info_table2, 2, lv_obj_get_width(info_table2) / 3);
    lv_obj_align(info_table2, LV_ALIGN_TOP_MID, 0, 0);

    lv_obj_add_event_cb(info_table2, draw_part_event_cb, LV_EVENT_DRAW_PART_BEGIN, NULL);
    lv_obj_add_event_cb(info_table2, change_event_cb, LV_EVENT_VALUE_CHANGED, NULL);

    update_info_table();

    SCR_FUNC_TYPE *_user_data = malloc(sizeof(SCR_FUNC_TYPE));
    _user_data->load_func = info_scr_load_func;
    _user_data->refr_func = info_scr_refr_func;
    _user_data->quit_func = info_scr_quit_func;

    scr_add_user_data(info_scr, E_INFO_SCR, _user_data);
}
