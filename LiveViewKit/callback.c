//
//  callback.c
//  LiveViewKit
//
//  Created by Danylo Kostyshyn on 26.01.2022.
//

#include "callback.h"

log_cb_t global_log_cb;

void init_log_cb(log_cb_t log_cb) {
    global_log_cb = log_cb;
}
