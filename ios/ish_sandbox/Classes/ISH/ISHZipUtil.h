#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ISHZipUtil : NSObject

/// Extract a ZIP archive to a destination directory. Overwrites existing files.
+ (BOOL)extractZipAtURL:(NSURL *)zipURL toDirectory:(NSURL *)destinationURL error:(NSError **)outError;

@end

NS_ASSUME_NONNULL_END
