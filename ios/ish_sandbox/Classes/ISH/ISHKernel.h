#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const ISHProcessExitedNotification;

/// Minimal Objective-C wrapper around the iSH-ARM64 kernel.
@interface ISHKernel : NSObject

+ (ISHKernel *)shared;

@property (nonatomic, readonly) BOOL isBooted;

/// Boot the kernel with the rootfs at `rootPath` (containing data/ and meta.db).
- (int)bootWithRootPath:(NSString *)rootPath;

/// Execute a command in the iSH environment.
- (int)executeCommand:(NSArray<NSString *> *)command;

/// Send UTF-8 input to the active terminal.
- (void)sendInput:(NSString *)input;

@end

NS_ASSUME_NONNULL_END
