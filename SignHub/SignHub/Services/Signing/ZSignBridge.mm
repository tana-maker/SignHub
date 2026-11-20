//
//  ZSignBridge.mm
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

#import "ZSignBridge.h"
#include "zsign_wrapper.hpp"

@implementation ZSignBridge

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
                       error:(NSError * _Nullable * _Nullable)error {
    
    ZSign::ZSignEngine engine;
    
    if (logBlock) {
        engine.setLogCallback([logBlock](const std::string& msg, int level) {
            NSString *nsMsg = [NSString stringWithUTF8String:msg.c_str()];
            dispatch_async(dispatch_get_main_queue(), ^{
                logBlock(nsMsg, (NSInteger)level);
            });
        });
    }
    
    ZSign::SignOptions options;
    options.appPath = std::string([appBundlePath UTF8String]);
    options.p12Path = std::string([p12Path UTF8String]);
    options.p12Password = std::string([p12Password UTF8String]);
    options.provPath = std::string([provisionFilePath UTF8String]);
    
    if (customBundleId) options.customBundleId = std::string([customBundleId UTF8String]);
    if (customBundleName) options.customBundleName = std::string([customBundleName UTF8String]);
    if (customBundleVersion) options.customBundleVersion = std::string([customBundleVersion UTF8String]);
    
    for (NSString *path in dylibPaths) {
        options.dylibPaths.push_back(std::string([path UTF8String]));
    }
    
    options.removeAppExtensions = removeAppExtensions;
    options.removeSupportedDevices = removeSupportedDevices;
    options.enableFileSharing = enableFileSharing;
    options.enableiPadFullscreen = enableiPadFullscreen;
    options.zipCompressionLevel = (int)compressionLevel;
    
    bool success = engine.signAppBundle(options);
    if (!success && error) {
        *error = [NSError errorWithDomain:@"com.signhub.zsign"
                                     code:-1
                                 userInfo:@{NSLocalizedDescriptionKey: @"zsign codesigning operation failed."}];
    }
    
    return success ? YES : NO;
}

@end
