#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ISHShellExecutor : NSObject

/// Execute a shell command inside iSH. Prototype: does not stream output.
+ (int)executeCommand:(NSString *)command
         lineCallback:(nullable void (^)(NSString *line, BOOL isStdErr))lineCallback
           completion:(nullable void (^)(int exitCode, NSString *output, NSString *error))completion;

@end

NS_ASSUME_NONNULL_END
