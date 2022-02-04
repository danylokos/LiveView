//
//  LVContext.m
//  LiveViewKit
//
//  Created by Danylo Kostyshyn on 30.01.2022.
//

#import "LVContext.h"

#include "libuvc/libuvc.h"
#include <stdio.h>
#include <unistd.h>

#define printf(...) {\
    char str[200];\
    sprintf(str, __VA_ARGS__);\
    [self.delegate context:self logMessage:str]; \
    }

#define uvc_perror(res, msg) {\
    printf("%s: %s (%d)\n", msg, uvc_strerror(res), res);\
    }

@interface LVContext () {
    uvc_context_t *ctx;
    uvc_device_t *dev;
    uvc_device_handle_t *devh;
    uvc_stream_ctrl_t ctrl;
    uvc_error_t res;
}
@property (strong, nonatomic) NSThread *uvcThread;
@end

@implementation LVContext

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LVContext *context;
    dispatch_once(&onceToken, ^{
        context = [[LVContext alloc] init];
    });
    return context;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // start alerts loop
        [self uvcInit];
    }
    return self;
}

- (void)start {
    [self uvcOpenDevice];
    if (devh) {
        [self uvcGetFrameDescriptors];
        [self uvcStartStreaming];
    }
}

- (void)reload {
    if (devh) {
        [self uvcStopStreaming];
    }
    if (devh && dev) {
        [self uvcCloseDevice];
    }
    if (ctx) {
        [self uvcDeinit];
    }
    [self uvcInit];
    [self start];
}

- (void)changeFrameDesc:(LVFrameDesc)frameDesc {
    [self uvcStopStreaming];
    [self uvcStartStreamingWithFrameDesc:frameDesc];
}

- (int)uvcInit {
    /* Initialize a UVC service context. Libuvc will set up its own libusb
     * context. Replace NULL with a libusb_context pointer to run libuvc
     * from an existing libusb context. */
    res = uvc_init(&ctx, NULL);
    
    if (res < 0) {
        uvc_perror(res, "uvc_init");
        return res;
    }
    
    printf("UVC initialized\n");
    return 0;
}

- (int)uvcOpenDevice {
    /* Locates the first attached UVC device, stores in dev */
    res = uvc_find_device(ctx, &dev, 0, 0, NULL); /* filter devices: vendor_id, product_id, "serial_num" */
    
    if (res < 0) {
        uvc_perror(res, "uvc_find_device"); /* no devices found */
        return res;
    }
    printf("Device found\n");
    
    /* Try to open the device: requires exclusive access */
    res = uvc_open(dev, &devh);
    
    if (res < 0) {
        uvc_perror(res, "uvc_open"); /* unable to open device */
        return res;
    }
    
    printf("Device opened\n");
    
    /* Print out a message containing all the information that libuvc
     * knows about the device */
    uvc_print_diag(devh, stdout);
    
    return 0;
}

- (int)uvcGetFrameDescriptors {
    // Select uncompressed format
    const uvc_format_desc_t *format_desc = uvc_get_format_descs(devh);
    while (format_desc && format_desc->bDescriptorSubtype != UVC_VS_FORMAT_UNCOMPRESSED) {
        format_desc = format_desc->next;
    }
    
    // format_desc->bNumFrameDescriptors returns 0
    uint8_t bNumFrameDescriptors = 0;
    const uvc_frame_desc_t *frame_desc = format_desc->frame_descs;
    while (frame_desc) {
        frame_desc = frame_desc->next;
        bNumFrameDescriptors += 1;
    }

    LVFrameDesc *frameDescs = calloc(bNumFrameDescriptors, sizeof(LVFrameDesc));
    frame_desc = format_desc->frame_descs;
    int idx = 0;
    while (frame_desc) {
        LVFrameDesc desc;
        desc.width = frame_desc->wWidth;
        desc.height = frame_desc->wHeight;
        desc.fps = 10000000 / frame_desc->dwDefaultFrameInterval;
        frameDescs[idx++] = desc;
        frame_desc = frame_desc->next;
    }
    [self.delegate context:self didUpdateFrameDescriptions:frameDescs count:bNumFrameDescriptors];
    
    return 0;
}

- (const uvc_format_desc_t *)uvcGetUncompressedFormatDesc {
    const uvc_format_desc_t *format_desc = uvc_get_format_descs(devh);
    while (format_desc && format_desc->bDescriptorSubtype != UVC_VS_FORMAT_UNCOMPRESSED) {
        format_desc = format_desc->next;
    }
    
    if (format_desc == NULL) {
        printf("Can't find uncompressed format\n");
        return NULL;
    }
    
    return format_desc;
}

- (int)uvcStartStreaming {
    const uvc_format_desc_t *format_desc = [self uvcGetUncompressedFormatDesc];
    
    LVFrameDesc frameDesc;
    frameDesc.width = 640;
    frameDesc.height = 480;
    frameDesc.fps = 30;
        
    const uvc_frame_desc_t *frame_desc = format_desc->frame_descs;
    if (frame_desc) {
        frameDesc.width = frame_desc->wWidth;
        frameDesc.height = frame_desc->wHeight;
        frameDesc.fps = 10000000 / frame_desc->dwDefaultFrameInterval;
    }

    return [self uvcStartStreamingWithFrameDesc:frameDesc];
}

- (int)uvcStartStreamingWithFrameDesc:(LVFrameDesc)frameDesc {
    const uvc_format_desc_t *format_desc = [self uvcGetUncompressedFormatDesc];
    enum uvc_frame_format frame_format = UVC_FRAME_FORMAT_YUYV;

    // Defaults
    int width = frameDesc.width;
    int height = frameDesc.height;
    int fps = frameDesc.fps;

    printf("\nFormat: (%4s) %dx%d %dfps\n", format_desc->fourccFormat, width, height, fps);
    
    /* Try to negotiate first stream profile */
    res = uvc_get_stream_ctrl_format_size(devh, &ctrl, /* result stored in ctrl */
                                          frame_format,
                                          width, height, fps); /* width, height, fps */
    
    /* Print out the result */
    uvc_print_stream_ctrl(&ctrl, stdout);
    
    if (res < 0) {
        uvc_perror(res, "get_mode"); /* device doesn't provide a matching stream */
        return res;
    }
    /* Start the video stream. The library will call user function cb:
     *   cb(frame, (void *) 12345)
     */
    res = uvc_start_streaming(devh, &ctrl, uvc_frame_cb, (__bridge void *)self, 0);
    
    if (res < 0) {
        uvc_perror(res, "start_streaming"); /* unable to start stream */
        return res;
    }
    
    printf("Streaming...\n");
    
    /* enable auto exposure - see uvc_set_ae_mode documentation */
    printf("Enabling auto exposure ...\n");
    const uint8_t UVC_AUTO_EXPOSURE_MODE_AUTO = 2;
    res = uvc_set_ae_mode(devh, UVC_AUTO_EXPOSURE_MODE_AUTO);
    if (res == UVC_SUCCESS) {
        printf(" ... enabled auto exposure\n");
    } else if (res == UVC_ERROR_PIPE) {
        /* this error indicates that the camera does not support the full AE mode;
         * try again, using aperture priority mode (fixed aperture, variable exposure time) */
        printf(" ... full AE not supported, trying aperture priority mode\n");
        const uint8_t UVC_AUTO_EXPOSURE_MODE_APERTURE_PRIORITY = 8;
        res = uvc_set_ae_mode(devh, UVC_AUTO_EXPOSURE_MODE_APERTURE_PRIORITY);
        if (res < 0) {
            uvc_perror(res, " ... uvc_set_ae_mode failed to enable aperture priority mode");
        } else {
            printf(" ... enabled aperture priority auto exposure mode\n");
        }
    } else {
        uvc_perror(res, " ... uvc_set_ae_mode failed to enable auto exposure mode");
    }

    return 0;
}

- (int)uvcStopStreaming {
    /* End the stream. Blocks until last callback is serviced */
    uvc_stop_streaming(devh);
    printf("Done streaming.\n");
    return 0;
}

- (int)uvcCloseDevice {
    /* Release our handle on the device */
    uvc_close(devh);
    printf("Device closed\n");
    
    /* Release the device descriptor */
    uvc_unref_device(dev);
    return 0;
}

- (int)uvcDeinit {
    /* Close the UVC context. This closes and cleans up any existing device handles,
     * and it closes the libusb context if one was not provided. */
    uvc_exit(ctx);
    printf("UVC exited\n");
    return 0;
}

/* This callback function runs once per frame. Use it to perform any
 * quick processing you need, or have it put the frame into your application's
 * input queue. If this function takes too long, you'll start losing frames. */
void uvc_frame_cb(uvc_frame_t *frame, void *ptr) {
    LVContext *lvContext = (__bridge LVContext *)(ptr);
    [lvContext processFrame:frame];
}

- (void)processFrame:(uvc_frame_t *)frame {
    uvc_frame_t *rgb;
    uvc_error_t ret;
    /* FILE *fp;
     * static int jpeg_count = 0;
     * static const char *H264_FILE = "iOSDevLog.h264";
     * static const char *MJPEG_FILE = ".jpeg";
     * char filename[16]; */
    
    /* We'll convert the image from YUV/JPEG to rgb, so allocate space */
    rgb = uvc_allocate_frame(frame->width * frame->height * 3);
    if (!rgb) {
        printf("unable to allocate rgb frame!\n");
        return;
    }
    
//    printf("callback! frame_format = %d, width = %d, height = %d, length = %lu\n",
//           frame->frame_format, frame->width, frame->height, frame->data_bytes);
    
    switch (frame->frame_format) {
        case UVC_FRAME_FORMAT_H264:
            /* use `ffplay H264_FILE` to play */
            /* fp = fopen(H264_FILE, "a");
             * fwrite(frame->data, 1, frame->data_bytes, fp);
             * fclose(fp); */
            break;
        case UVC_COLOR_FORMAT_MJPEG:
            /* sprintf(filename, "%d%s", jpeg_count++, MJPEG_FILE);
             * fp = fopen(filename, "w");
             * fwrite(frame->data, 1, frame->data_bytes, fp);
             * fclose(fp); */
            break;
        case UVC_COLOR_FORMAT_YUYV:
            /* Do the rgb conversion */
            ret = uvc_any2rgb(frame, rgb);
            if (ret) {
                uvc_perror(ret, "uvc_any2rgb");
                uvc_free_frame(rgb);
                return;
            }
            break;
        default:
            break;
    }
    
    if (frame->sequence % 30 == 0) {
        printf(" * got image %u\n",  frame->sequence);
    }
    
    uint8_t *frame_data = malloc(rgb->data_bytes);
    memcpy(frame_data, rgb->data, rgb->data_bytes);
    
    [self.delegate context:self
       didReceiveFrameData:frame_data
                     width:rgb->width
                    height:rgb->height];

    uvc_free_frame(rgb);
}

@end
