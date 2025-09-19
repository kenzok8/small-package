#include "ui_common.h"


SYS_PARM_TYPE sys_parm;

// 屏幕刷新加载逻辑

static E_SCREEN_ID cur_scr = E_MAX_SCR;
static SCR_FUNC_TYPE *act_scr_func = NULL;
static SCR_FUNC_TYPE *top_layer_func = NULL;
static SCR_LIST_TYPE scr_parm_list[E_MAX_SCR] = {0};
static disp_size_t disp_size;

int disp_hor;
int disp_ver;
//int disp_hor = 480;
//int disp_ver = 320;
//int disp_hor = 1024;
//int disp_ver = 600;
//int disp_hor = 800;
//int disp_ver = 480;
//int disp_hor = 1280;
//int disp_ver = 720;

E_SCREEN_ID home_sid = E_HOME_SCR;
E_SCREEN_ID info_sid = E_INFO_SCR;
const lv_font_t *font_shs_10b;
const lv_font_t *font_shs_12b;
const lv_font_t *font_shs_16b;
const lv_font_t *font_shs_10r;
const lv_font_t *font_shs_8b;
const lv_font_t *font_mont_16;
char *icon1_path;
char *icon2_path;
char *icon3_path;

lv_obj_t *test_area;
lv_obj_t *test_area2;
lv_obj_t *arc1;
lv_obj_t *arc2;
lv_obj_t *top_cont;


void scr_add_user_data(lv_obj_t *scr, E_SCREEN_ID id, SCR_FUNC_TYPE *desc)
{
    scr_parm_list[id].scr = scr;
    scr_parm_list[id].user_data = desc;

    if(id == E_TOP_LAYER)
        top_layer_func = desc;
}

void scr_refr_func(Event_Data_t *args)
{
    if(act_scr_func)
        act_scr_func->refr_func(args);
    if(top_layer_func)
        top_layer_func->refr_func(args);
}

void scr_quit_func(void *args)
{
    if(act_scr_func != NULL)
        act_scr_func->quit_func(args);
}

void scr_load_func(E_SCREEN_ID id, void *args)
{
    if(id >= E_MAX_SCR)
    {
        APP_DEBUG("%s value overflow", __func__);
        return;
    }
    cur_scr = id;
    if((scr_parm_list[id].scr == NULL) || (scr_parm_list[id].user_data == NULL))
        return;

    if(act_scr_func != NULL)
        act_scr_func->quit_func(args);

    scr_parm_list[id].user_data->load_func(args);

    if(top_layer_func != NULL)
        top_layer_func->load_func(&id);

    lv_scr_load(scr_parm_list[id].scr);
    act_scr_func = scr_parm_list[id].user_data;
}

E_SCREEN_ID scr_act_get(void)
{
    return cur_scr;
}

void click_load_scr_event_cb(lv_event_t * e)
{
	lv_event_code_t code = lv_event_get_code(e);
    lv_obj_t * obj = lv_event_get_target(e);
	if(code == LV_EVENT_CLICKED)
	{
        if(e->user_data != NULL)
        {
            E_SCREEN_ID *pid = (E_SCREEN_ID *)e->user_data;
            printf("*pid = %d\n", *pid);
            scr_load_func(*pid, NULL);
        }
	}
}

void lv_font_init(void)
{
    if(disp_hor <= 480) disp_size = DISP_SMALL;
    else if(disp_hor <= 800) disp_size = DISP_MEDIUM;
    else disp_size = DISP_LARGE;
    
    static lv_ft_info_t shs_10b;
    static lv_ft_info_t shs_12b;
    static lv_ft_info_t shs_16b;
    static lv_ft_info_t shs_10r;
    static lv_ft_info_t shs_8b;
    int scale = 10;
    if (disp_hor > 480) {
      scale = disp_hor*10/480;
    }

    if(disp_size == DISP_LARGE) {
        shs_10b.name = FONT_PATH"SourceHanSansCN-Bold.otf";
        shs_10b.weight = 10 * scale / 10;
        shs_10b.style = FT_FONT_STYLE_NORMAL;
        shs_10b.mem = NULL;
        if(!lv_ft_font_init(&shs_10b)) {
            LV_LOG_ERROR("create failed.");
        }
        shs_12b.name = FONT_PATH"SourceHanSansCN-Bold.otf";
        shs_12b.weight = 12 * scale / 10;
        shs_12b.style = FT_FONT_STYLE_NORMAL;
        shs_12b.mem = NULL;
        if(!lv_ft_font_init(&shs_12b)) {
            LV_LOG_ERROR("create failed.");
        }
        shs_16b.name = FONT_PATH"SourceHanSansCN-Bold.otf";
        shs_16b.weight = 16 * scale / 10;
        shs_16b.style = FT_FONT_STYLE_NORMAL;
        shs_16b.mem = NULL;
        if(!lv_ft_font_init(&shs_16b)) {
            LV_LOG_ERROR("create failed.");
        }
        shs_10r.name = FONT_PATH"SourceHanSansCN-Normal.otf";
        shs_10r.weight = 10 * scale / 10;
        shs_10r.style = FT_FONT_STYLE_NORMAL;
        shs_10r.mem = NULL;
        if(!lv_ft_font_init(&shs_10r)) {
            LV_LOG_ERROR("create failed.");
        }
        shs_8b.name = FONT_PATH"SourceHanSansCN-Bold.otf";
        shs_8b.weight = 8 * scale / 10;
        shs_8b.style = FT_FONT_STYLE_NORMAL;
        shs_8b.mem = NULL;
        if(!lv_ft_font_init(&shs_8b)) {
            LV_LOG_ERROR("create failed.");
        }
        font_mont_16 = &lv_font_montserrat_26;
        icon1_path = ASSET_PATH"icon1_l.png";
        icon2_path = ASSET_PATH"icon2_l.png";
        icon3_path = ASSET_PATH"icon3_l.png";
    }
    else if(disp_size == DISP_MEDIUM) {
        shs_10b.name = FONT_PATH"SourceHanSansCN-Bold.otf";
        shs_10b.weight = 10 * scale / 10;
        shs_10b.style = FT_FONT_STYLE_NORMAL;
        shs_10b.mem = NULL;
        if(!lv_ft_font_init(&shs_10b)) {
            LV_LOG_ERROR("create failed.");
        }
        shs_12b.name = FONT_PATH"SourceHanSansCN-Bold.otf";
        shs_12b.weight = 12 * scale / 10;
        shs_12b.style = FT_FONT_STYLE_NORMAL;
        shs_12b.mem = NULL;
        if(!lv_ft_font_init(&shs_12b)) {
            LV_LOG_ERROR("create failed.");
        }
        shs_16b.name = FONT_PATH"SourceHanSansCN-Bold.otf";
        shs_16b.weight = 16 * scale / 10;
        shs_16b.style = FT_FONT_STYLE_NORMAL;
        shs_16b.mem = NULL;
        if(!lv_ft_font_init(&shs_16b)) {
            LV_LOG_ERROR("create failed.");
        }
        shs_10r.name = FONT_PATH"SourceHanSansCN-Normal.otf";
        shs_10r.weight = 10 * scale / 10;
        shs_10r.style = FT_FONT_STYLE_NORMAL;
        shs_10r.mem = NULL;
        if(!lv_ft_font_init(&shs_10r)) {
            LV_LOG_ERROR("create failed.");
        }
        shs_8b.name = FONT_PATH"SourceHanSansCN-Bold.otf";
        shs_8b.weight = 8 * scale / 10;
        shs_8b.style = FT_FONT_STYLE_NORMAL;
        shs_8b.mem = NULL;
        if(!lv_ft_font_init(&shs_8b)) {
            LV_LOG_ERROR("create failed.");
        }
        font_mont_16 = &lv_font_montserrat_22;
        icon1_path = ASSET_PATH"icon1_m.png";
        icon2_path = ASSET_PATH"icon2_m.png";
        icon3_path = ASSET_PATH"icon3_m.png";
    }
    else {
        shs_10b.name = FONT_PATH"SourceHanSansCN-Bold.otf";
        shs_10b.weight = 10 * scale / 10;
        shs_10b.style = FT_FONT_STYLE_NORMAL;
        shs_10b.mem = NULL;
        if(!lv_ft_font_init(&shs_10b)) {
            LV_LOG_ERROR("create failed.");
        }
        shs_12b.name = FONT_PATH"SourceHanSansCN-Bold.otf";
        shs_12b.weight = 12 * scale / 10;
        shs_12b.style = FT_FONT_STYLE_NORMAL;
        shs_12b.mem = NULL;
        if(!lv_ft_font_init(&shs_12b)) {
            LV_LOG_ERROR("create failed.");
        }
        shs_16b.name = FONT_PATH"SourceHanSansCN-Bold.otf";
        shs_16b.weight = 16 * scale / 10;
        shs_16b.style = FT_FONT_STYLE_NORMAL;
        shs_16b.mem = NULL;
        if(!lv_ft_font_init(&shs_16b)) {
            LV_LOG_ERROR("create failed.");
        }
        shs_10r.name = FONT_PATH"SourceHanSansCN-Normal.otf";
        shs_10r.weight = 10 * scale / 10;
        shs_10r.style = FT_FONT_STYLE_NORMAL;
        shs_10r.mem = NULL;
        if(!lv_ft_font_init(&shs_10r)) {
            LV_LOG_ERROR("create failed.");
        }
        shs_8b.name = FONT_PATH"SourceHanSansCN-Bold.otf";
        shs_8b.weight = 8 * scale / 10;
        shs_8b.style = FT_FONT_STYLE_NORMAL;
        shs_8b.mem = NULL;
        if(!lv_ft_font_init(&shs_8b)) {
            LV_LOG_ERROR("create failed.");
        }
        font_mont_16 = &lv_font_montserrat_16;
        icon1_path = ASSET_PATH"icon1_s.png";
        icon2_path = ASSET_PATH"icon2_s.png";
        icon3_path = ASSET_PATH"icon3_s.png";
    }

    font_shs_10b = shs_10b.font;
    font_shs_12b = shs_12b.font;
    font_shs_16b = shs_16b.font;
    font_shs_10r = shs_10r.font;
    font_shs_8b = shs_8b.font;
}
