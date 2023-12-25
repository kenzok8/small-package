#ifdef UA2F_ENABLE_UCI
#include <uci.h>
#include <string.h>
#include <syslog.h>

#include "config.h"

struct ua2f_config config = {
        .use_custom_ua = false,
        .custom_ua = NULL,
};

void load_config() {
    const __auto_type ctx = uci_alloc_context();
    if (!ctx) {
        syslog(LOG_ERR, "Failed to allocate uci context");
        return;
    }

    struct uci_package *package;
    if (uci_load(ctx, "ua2f", &package) != UCI_OK) {
        goto cleanup;
    }

    // find ua2f.main.custom_ua
    const __auto_type section = uci_lookup_section(ctx, package, "main");
    if (!section) {
        goto cleanup;
    }

    const __auto_type custom_ua = uci_lookup_option_string(ctx, section, "custom_ua");
    if (!custom_ua) {
        goto cleanup;
    }
    if (strlen(custom_ua) > 0) {
        config.use_custom_ua = true;
        config.custom_ua = strdup(custom_ua);
    }

    cleanup:
    uci_free_context(ctx);
}
#endif