#include "ui_common.h"

static lv_obj_t *top_layer;
static lv_obj_t *top_icon1;

static void top_layer_load_func(void *arg)
{
    if(arg == NULL)
        return;

    E_SCREEN_ID *id = (E_SCREEN_ID *)arg;

    if(*id == E_HOME_SCR)
        lv_obj_set_parent(top_cont, test_area);
    else
        lv_obj_set_parent(top_cont, test_area2);
}

static void top_layer_refr_func(Event_Data_t *arg)
{
    if(arg == NULL)
    {

    }
    else
    {
        if(arg->eEventID == E_KEY_EVENT)
            ;
    }
}

static void top_layer_quit_func(void *arg)
{

}

extern lv_obj_t *err_label;
extern lv_obj_t *date_label;
extern lv_obj_t *time_label;
void top_layer_create(void)
{
    top_layer = lv_layer_top();

    lv_obj_t *label1;
    lv_obj_t *label2;
    lv_obj_t *label3;

    top_cont = lv_obj_create(test_area);
    lv_obj_set_size(top_cont, LV_PCT(100), LV_PCT(8));
    lv_obj_set_style_radius(top_cont, 0, 0);
    lv_obj_set_style_bg_opa(top_cont, 0, 0);
    lv_obj_set_style_border_width(top_cont, 0, 0);
    lv_obj_set_style_pad_all(top_cont, 0, 0);
    lv_obj_clear_flag(top_cont, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_align(top_cont, LV_ALIGN_TOP_MID, 0, 0);

    static lv_coord_t col_dsc11[] = {LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};
    static lv_coord_t row_dsc11[] = {LV_GRID_FR(1), LV_GRID_TEMPLATE_LAST};
    lv_obj_set_grid_dsc_array(top_cont, col_dsc11, row_dsc11);
    
    label1 = lv_label_create(top_cont);
    lv_obj_set_style_text_font(label1, font_shs_12b, 0);
    lv_obj_set_style_text_color(label1, lv_color_make(184, 184, 190), 0);
    lv_label_set_text(label1, "");
    err_label = label1;

    label2 = lv_label_create(top_cont);
    lv_obj_set_style_text_font(label2, font_shs_12b, 0);
    lv_obj_set_style_text_color(label2, lv_color_white(), 0);
    lv_label_set_text(label2, "00:00");
    time_label = label2;

    label3 = lv_label_create(top_cont);
    lv_obj_set_style_text_font(label3, font_shs_12b, 0);
    lv_obj_set_style_text_color(label3, lv_color_white(), 0);
    lv_label_set_text(label3, "2025.00.00");
    date_label = label3;

    lv_obj_set_grid_cell(label1, LV_GRID_ALIGN_START, 0, 1, LV_GRID_ALIGN_CENTER, 0, 1);
    lv_obj_set_grid_cell(label2, LV_GRID_ALIGN_CENTER, 1, 1, LV_GRID_ALIGN_CENTER, 0, 1);
    lv_obj_set_grid_cell(label3, LV_GRID_ALIGN_END, 2, 1, LV_GRID_ALIGN_CENTER, 0, 1);

    
    SCR_FUNC_TYPE *_user_data = malloc(sizeof(SCR_FUNC_TYPE));
    _user_data->load_func = top_layer_load_func;
    _user_data->refr_func = top_layer_refr_func;
    _user_data->quit_func = top_layer_quit_func;

    scr_add_user_data(top_layer, E_TOP_LAYER, _user_data);
}
