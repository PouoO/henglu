#import "ISHKernel.h"

@implementation ISHShellExecutor

+ (int)executeCommand:(NSString *)command
         lineCallback:(nullable void (^)(NSString *line, BOOL isStdErr))lineCallback
           completion:(nullable void (^)(int exitCode, NSString *output, NSString *error))completion {
    // For the prototype, run synchronously via the kernel. A full implementation
    // would drive the TTY and stream output. Here we just start /bin/sh -c.
    int pid = [ISHKernel.shared executeCommand:@[@"/bin/sh", @"-c", command]];
    if (pid < 0) {
        if (completion) completion(-1, @"", @"failed to start shell");
    }
    return pid;
}

@end
