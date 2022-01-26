//
//  callback.h
//  LiveView
//
//  Created by Danylo Kostyshyn on 25.01.2022.
//

#ifndef callback_h
#define callback_h

typedef void (*log_cb_t)(char *);

extern log_cb_t global_log_cb;

void init_log_cb(log_cb_t log_cb);

#define printf(...) {\
    char str[200];\
    sprintf(str, __VA_ARGS__);\
    (*global_log_cb)(str);\
    }

#endif /* callback_h */
