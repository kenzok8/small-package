#include "ui_common.h"

static lv_obj_t *xxx_scr;
static int refr_lock = 1;

static void xxx_scr_obj_create(void);
static void xxx_scr_obj_delete(void);

static void xxx_scr_load_func(void *arg)
{
    // ... ui_init
    xxx_scr_obj_create();
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

static void xxx_scr_refr_func(Event_Data_t *arg)
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

static void xxx_scr_quit_func(void *arg)
{
    refr_lock = 1;
    // ... ui_del
    xxx_scr_obj_delete();
}


static void xxx_scr_obj_create(void)
{

}

static void xxx_scr_obj_delete(void)
{
    lv_obj_clean(xxx_scr);
}


void xxx_scr_create(void)
{
    xxx_scr = lv_obj_create(NULL);
    lv_obj_set_style_bg_color(xxx_scr, lv_color_black(), 0);

    SCR_FUNC_TYPE *_user_data = malloc(sizeof(SCR_FUNC_TYPE));
    _user_data->load_func = xxx_scr_load_func;
    _user_data->refr_func = xxx_scr_refr_func;
    _user_data->quit_func = xxx_scr_quit_func;

    scr_add_user_data(xxx_scr, E_MAX_SCR, _user_data);
}
