#import "ISHKernel.h"

#include "ish/misc.h"
#include "ish/debug.h"
#include "ish/kernel/init.h"
#include "ish/kernel/task.h"
#include "ish/kernel/calls.h"
#include "ish/kernel/fs.h"
#include "ish/kernel/errno.h"
#include "ish/fs/fake.h"
#include "ish/fs/tty.h"
#include "ish/fs/dev.h"
#include "ish/fs/devices.h"

NSNotificationName const ISHProcessExitedNotification = @"ISHProcessExitedNotification";

static void handle_exit(struct task *task, int code) {
    pid_t pid = task->pid;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ISHProcessExitedNotification
                                                            object:nil
                                                          userInfo:@{@"pid": @(pid), @"code": @(code)}];
    });
}

@implementation ISHKernel {
    BOOL _booted;
}

+ (ISHKernel *)shared {
    static ISHKernel *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ instance = [[ISHKernel alloc] init]; });
    return instance;
}

- (BOOL)isBooted {
    return _booted;
}

- (int)bootWithRootPath:(NSString *)rootPath {
    NSString *dataPath = [rootPath stringByAppendingPathComponent:@"data"];
    int err = mount_root(&fakefs, dataPath.fileSystemRepresentation);
    if (err < 0) {
        NSLog(@"[ISHKernel] mount_root failed: %d", err);
        return err;
    }

    err = become_first_process();
    if (err < 0) {
        NSLog(@"[ISHKernel] become_first_process failed: %d", err);
        return err;
    }
    current->thread = pthread_self();

    [self createDeviceNodes];

    err = do_mount(&procfs, "proc", "/proc", "", 0);
    if (err < 0) {
        NSLog(@"[ISHKernel] mount /proc failed: %d", err);
    }

    extern void (*exit_hook)(struct task *, int);
    exit_hook = handle_exit;

    _booted = YES;
    NSLog(@"[ISHKernel] booted at %@", rootPath);
    return 0;
}

- (void)createDeviceNodes {
    generic_mkdirat(AT_PWD, "/dev", 0755);
    generic_mkdirat(AT_PWD, "/dev/pts", 0755);

    generic_mknodat(AT_PWD, "/dev/tty1", S_IFCHR|0666, dev_make(TTY_CONSOLE_MAJOR, 1));
    generic_mknodat(AT_PWD, "/dev/tty2", S_IFCHR|0666, dev_make(TTY_CONSOLE_MAJOR, 2));
    generic_mknodat(AT_PWD, "/dev/console", S_IFCHR|0666, dev_make(TTY_CONSOLE_MAJOR, 1));
    generic_mknodat(AT_PWD, "/dev/tty", S_IFCHR|0666, dev_make(TTY_MAJOR, 0));
    generic_mknodat(AT_PWD, "/dev/ptmx", S_IFCHR|0666, dev_make(TTY_ALTERNATE_MAJOR, 2));

    generic_mknodat(AT_PWD, "/dev/null", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_NULL_MINOR));
    generic_mknodat(AT_PWD, "/dev/zero", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_ZERO_MINOR));
    generic_mknodat(AT_PWD, "/dev/full", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_FULL_MINOR));
    generic_mknodat(AT_PWD, "/dev/random", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_RANDOM_MINOR));
    generic_mknodat(AT_PWD, "/dev/urandom", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_URANDOM_MINOR));
}

- (int)executeCommand:(NSArray<NSString *> *)command {
    if (command.count == 0) return -1;

    char argv[4096];
    size_t pos = 0;
    for (NSString *arg in command) {
        const char *carg = arg.UTF8String;
        size_t len = strlen(carg) + 1;
        if (pos + len >= sizeof(argv)) break;
        memcpy(argv + pos, carg, len);
        pos += len;
    }
    argv[pos] = '\0';

    const char *envp = "TERM=xterm-256color\0HOME=/root\0PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin\0";

    int err = do_execve(command[0].UTF8String, (int)command.count, argv, envp);
    if (err < 0) {
        NSLog(@"[ISHKernel] do_execve failed: %d", err);
        return err;
    }

    task_start(current);
    return 0;
}

- (void)sendInput:(NSString *)input {
    NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
    struct tty *tty = tty_get(TTY_CONSOLE_MAJOR, 1);
    if (tty) {
        tty_input(tty, data.bytes, data.length, 0);
        tty_release(tty);
    }
}

@end
