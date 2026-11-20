//
//  ZSignBridge.h
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZSignLogBlock)(NSString *message, NSInteger level);

@interface ZSignBridge : NSObject

/// Wraps zsign engine to sign an unzipped .app bundle
+ (BOOL)signAppBundleAtPath:(NSString *)appBundlePath
                    p12Path:(NSString *)p12Path
                p12Password:(NSString *)p12Password
          provisionFilePath:(NSString *)provisionFilePath
             customBundleId:(nullable NSString *)customBundleId
           customBundleName:(nullable NSString *)customBundleName
        customBundleVersion:(nullable NSString *)customBundleVersion
                 dylibPaths:(NSArray<NSString *> *)dylibPaths
        removeAppExtensions:(BOOL)removeAppExtensions
     removeSupportedDevices:(BOOL)removeSupportedDevices
          enableFileSharing:(BOOL)enableFileSharing
        enableiPadFullscreen:(BOOL)enableiPadFullscreen
         zipCompressionLevel:(NSInteger)compressionLevel
                    logBlock:(nullable ZSignLogBlock)logBlock
                       error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
