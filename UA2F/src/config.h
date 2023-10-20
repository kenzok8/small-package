#ifndef UA2F_CONFIG_H
#define UA2F_CONFIG_H

#include <stdbool.h>

struct ua2f_config {
    bool use_custom_ua;
    char *custom_ua;
};

void load_config();

extern struct ua2f_config config;

#endif //UA2F_CONFIG_H
