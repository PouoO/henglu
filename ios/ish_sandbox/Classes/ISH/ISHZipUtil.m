#import "ISHZipUtil.h"
#include <archive.h>
#include <archive_entry.h>

@implementation ISHZipUtil

+ (BOOL)extractZipAtURL:(NSURL *)zipURL toDirectory:(NSURL *)destinationURL error:(NSError **)outError {
    const char *zipPath = zipURL.fileSystemRepresentation;
    const char *destPath = destinationURL.fileSystemRepresentation;

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:destinationURL.path]) {
        [fm createDirectoryAtURL:destinationURL withIntermediateDirectories:YES attributes:nil error:outError];
        if (outError && *outError) return NO;
    }

    struct archive *a = archive_read_new();
    archive_read_support_format_zip(a);
    archive_read_support_compression_all(a);

    int r = archive_read_open_filename(a, zipPath, 10240);
    if (r != ARCHIVE_OK) {
        if (outError) {
            *outError = [NSError errorWithDomain:@"ISHZipUtil" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to open zip"}];
        }
        archive_read_free(a);
        return NO;
    }

    struct archive_entry *entry;
    BOOL success = YES;
    while (archive_read_next_header(a, &entry) == ARCHIVE_OK) {
        const char *entryPath = archive_entry_pathname(entry);
        if (!entryPath) continue;

        NSString *relativePath = [NSString stringWithUTF8String:entryPath];
        if (!relativePath) continue;

        NSURL *entryURL = [destinationURL URLByAppendingPathComponent:relativePath];

        mode_t mode = archive_entry_mode(entry);
        if (S_ISDIR(mode)) {
            [fm createDirectoryAtURL:entryURL withIntermediateDirectories:YES attributes:nil error:nil];
        } else {
            [fm createDirectoryAtURL:entryURL.URLByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
            NSMutableData *data = [NSMutableData data];
            const void *buff;
            size_t size;
            la_int64_t offset;
            while ((r = archive_read_data_block(a, &buff, &size, &offset)) == ARCHIVE_OK) {
                [data appendBytes:buff length:size];
            }
            [data writeToURL:entryURL options:NSDataWritingAtomic error:outError];
            if (outError && *outError) {
                success = NO;
                break;
            }
        }
    }

    archive_read_free(a);
    return success;
}

@end
