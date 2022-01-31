//
//  LVContext.h
//  LiveViewKit
//
//  Created by Danylo Kostyshyn on 30.01.2022.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@class LVContext;
@protocol LVContextDelegate <NSObject>
- (void)context:(LVContext *)context logMessage:(char * _Nullable)message;
- (void)context:(LVContext *)context didReceiveFrameData:(uint8_t *)data width:(size_t)width height:(size_t)height;
@end

@interface LVContext : NSObject
@property (weak, nonatomic) id<LVContextDelegate> delegate;
+ (instancetype)sharedInstance;
- (void)start;
@end

NS_ASSUME_NONNULL_END
