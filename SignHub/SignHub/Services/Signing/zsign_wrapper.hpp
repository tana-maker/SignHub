//
//  zsign_wrapper.hpp
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

#ifndef ZSIGN_WRAPPER_HPP
#define ZSIGN_WRAPPER_HPP

#include <string>
#include <vector>
#include <functional>

namespace ZSign {

typedef std::function<void(const std::string& logMessage, int logLevel)> LogCallback;

struct SignOptions {
    std::string appPath;
    std::string p12Path;
    std::string p12Password;
    std::string provPath;
    std::string customBundleId;
    std::string customBundleName;
    std::string customBundleVersion;
    std::vector<std::string> dylibPaths;
    bool removeAppExtensions = true;
    bool removeSupportedDevices = true;
    bool enableFileSharing = false;
    bool enableiPadFullscreen = true;
    int zipCompressionLevel = 6;
};

class ZSignEngine {
public:
    ZSignEngine();
    ~ZSignEngine();

    void setLogCallback(LogCallback callback);
    bool signAppBundle(const SignOptions& options);

private:
    LogCallback m_logCallback;
    void log(const std::string& msg, int level = 0);
    bool modifyInfoPlist(const SignOptions& options);
    bool injectDylibs(const SignOptions& options);
    bool signFolder(const std::string& folderPath, const std::string& p12Path, const std::string& password);
};

} // namespace ZSign

#endif /* ZSIGN_WRAPPER_HPP */
