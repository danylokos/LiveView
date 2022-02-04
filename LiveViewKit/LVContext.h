//
//  LVContext.h
//  LiveViewKit
//
//  Created by Danylo Kostyshyn on 30.01.2022.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

struct LVFrameDesc {
    uint16_t width;
    uint16_t height;
    uint32_t fps;
};
typedef struct LVFrameDesc LVFrameDesc;

NS_ASSUME_NONNULL_BEGIN

@class LVContext;
@protocol LVContextDelegate <NSObject>
- (void)context:(LVContext *)context logMessage:(char * _Nullable)message;
- (void)context:(LVContext *)context didUpdateFrameDescriptions:(LVFrameDesc *)frameDescs count:(uint8_t)count;
- (void)context:(LVContext *)context didReceiveFrameData:(uint8_t *)data width:(size_t)width height:(size_t)height;
@end

@interface LVContext : NSObject
@property (weak, nonatomic) id<LVContextDelegate> delegate;
+ (instancetype)sharedInstance;
- (void)start;
- (void)reload;
- (void)changeFrameDesc:(LVFrameDesc)frameDesc;
@end

NS_ASSUME_NONNULL_END
