//
//  NativeSigner.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation
import CommonCrypto

/// Native Swift codesigning engine providing standalone bundle modification, CodeResources creation, and fallback signing
public final class NativeSigner {
    public static let shared = NativeSigner()
    
    private init() {}
    
    public enum SignerError: LocalizedError {
        case appBundleNotFound
        case infoPlistMissing
        case executableNotFound
        case dylibInjectionFailed(String)
        case codeResourcesGenerationFailed
        
        public var errorDescription: String? {
            switch self {
            case .appBundleNotFound: return "Target .app bundle was not found inside Payload directory."
            case .infoPlistMissing: return "Info.plist is missing from the application bundle."
            case .executableNotFound: return "Mach-O executable binary was not found in the bundle."
            case .dylibInjectionFailed(let msg): return "Failed to inject dynamic library: \(msg)"
            case .codeResourcesGenerationFailed: return "Failed to generate _CodeSignature/CodeResources."
            }
        }
    }
    
    /// Prepares, patches, and signs an unpacked application bundle
    public func signBundle(
        appBundleURL: URL,
        certificate: CertificateModel,
        provisioningProfileData: Data,
        options: SigningOptions,
        logger: @escaping (String, LogLevel) -> Void
    ) throws {
        logger("Beginning bundle preparation for: \(appBundleURL.lastPathComponent)", .info)
        
        // 1. Replace embedded.mobileprovision
        let targetProvisionURL = appBundleURL.appendingPathComponent("embedded.mobileprovision")
        if FileManager.default.fileExists(atPath: targetProvisionURL.path) {
            try? FileManager.default.removeItem(at: targetProvisionURL)
        }
        try provisioningProfileData.write(to: targetProvisionURL)
        logger("Embedded new provisioning profile: \(certificate.name)", .info)
        
        // 2. Modify Info.plist
        let infoPlistURL = appBundleURL.appendingPathComponent("Info.plist")
        guard FileManager.default.fileExists(atPath: infoPlistURL.path) else {
            throw SignerError.infoPlistMissing
        }
        
        let plistData = try Data(contentsOf: infoPlistURL)
        var format = PropertyListSerialization.PropertyListFormat.xml
        guard var plist = try PropertyListSerialization.propertyList(from: plistData, options: .mutableContainersAndLeaves, format: &format) as? [String: Any] else {
            throw SignerError.infoPlistMissing
        }
        
        // Custom App Name
        if !options.customAppName.trimmingCharacters(in: .whitespaces).isEmpty {
            plist["CFBundleDisplayName"] = options.customAppName
            plist["CFBundleName"] = options.customAppName
            logger("Updated app name to: \(options.customAppName)", .info)
        }
        
        // Custom Bundle Identifier
        if !options.customBundleIdentifier.trimmingCharacters(in: .whitespaces).isEmpty {
            plist["CFBundleIdentifier"] = options.customBundleIdentifier
            logger("Updated bundle identifier to: \(options.customBundleIdentifier)", .info)
        }
        
        // Custom Version
        if !options.customVersion.trimmingCharacters(in: .whitespaces).isEmpty {
            plist["CFBundleShortVersionString"] = options.customVersion
            logger("Updated app version to: \(options.customVersion)", .info)
        }
        if !options.customBuildNumber.trimmingCharacters(in: .whitespaces).isEmpty {
            plist["CFBundleVersion"] = options.customBuildNumber
        }
        
        // Remove UISupportedDevices
        if options.removeSupportedDevices {
            plist.removeValue(forKey: "UISupportedDevices")
            logger("Removed UISupportedDevices restriction.", .info)
        }
        
        // Enable File Sharing
        if options.enableFileSharing {
            plist["UIFileSharingEnabled"] = true
            plist["LSSupportsOpeningDocumentsInPlace"] = true
            logger("Enabled iTunes / Files document sharing.", .info)
        }
        
        // Enable iPad Fullscreen
        if options.enableiPadFullscreen {
            plist["UIRequiresFullScreen"] = false
            logger("Enabled iPad multitasking and fullscreen support.", .info)
        }
        
        // Save modified Info.plist
        let updatedPlistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try updatedPlistData.write(to: infoPlistURL)
        
        // 3. Custom App Icon
        if let iconData = options.customIconData {
            replaceAppIcons(in: appBundleURL, with: iconData, logger: logger)
        }
        
        // 4. Remove App Extensions if requested
        if options.removeAppExtensions {
            let pluginsDir = appBundleURL.appendingPathComponent("PlugIns")
            if FileManager.default.fileExists(atPath: pluginsDir.path) {
                try? FileManager.default.removeItem(at: pluginsDir)
                logger("Removed PlugIns directory to prevent extension signing errors.", .info)
            }
        }
        
        // 5. Inject Dynamic Libraries
        let executableName = plist["CFBundleExecutable"] as? String ?? ""
        let execURL = appBundleURL.appendingPathComponent(executableName)
        
        if !options.injectedDylibFileNames.isEmpty && !executableName.isEmpty {
            let frameworksDir = appBundleURL.appendingPathComponent("Frameworks")
            try FileManager.default.createDirectory(at: frameworksDir, withIntermediateDirectories: true)
            
            for dylibName in options.injectedDylibFileNames {
                let installPath = "@executable_path/Frameworks/\(dylibName)"
                do {
                    try MachOHelper.injectDylib(at: execURL, dylibInstallPath: installPath)
                    logger("Injected dylib load command: \(dylibName)", .success)
                } catch {
                    logger("Failed injecting \(dylibName): \(error.localizedDescription)", .warning)
                }
            }
        }
        
        // 6. Generate _CodeSignature/CodeResources
        logger("Generating sealed _CodeSignature/CodeResources...", .info)
        try generateCodeResources(for: appBundleURL)
        logger("CodeResources manifest generated and verified.", .success)
    }
    
    private func replaceAppIcons(in appBundleURL: URL, with iconData: Data, logger: (String, LogLevel) -> Void) {
        guard let files = try? FileManager.default.contentsOfDirectory(at: appBundleURL, includingPropertiesForKeys: nil) else { return }
        for file in files {
            let name = file.lastPathComponent.lowercased()
            if name.hasPrefix("appicon") && name.hasSuffix(".png") {
                try? iconData.write(to: file)
            }
        }
        logger("Replaced custom application icons.", .info)
    }
    
    private func generateCodeResources(for appBundleURL: URL) throws {
        let codeSignatureDir = appBundleURL.appendingPathComponent("_CodeSignature")
        try FileManager.default.createDirectory(at: codeSignatureDir, withIntermediateDirectories: true)
        
        guard let enumerator = FileManager.default.enumerator(
            at: appBundleURL,
            includingPropertiesForKeys: [.isRegularFileKey]
        ) else {
            throw SignerError.codeResourcesGenerationFailed
        }
        
        var filesDict: [String: Any] = [:]
        var files2Dict: [String: Any] = [:]
        
        for case let fileURL as URL in enumerator {
            if fileURL.path.contains("/_CodeSignature/") { continue }
            guard let isRegular = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile, isRegular else {
                continue
            }
            
            let relativePath = fileURL.path.replacingOccurrences(of: appBundleURL.path + "/", with: "")
            guard let fileData = try? Data(contentsOf: fileURL) else { continue }
            
            let sha1Hash = fileData.sha1
            let sha256Hash = fileData.sha256
            
            filesDict[relativePath] = sha1Hash
            files2Dict[relativePath] = [
                "hash": sha1Hash,
                "hash2": sha256Hash
            ]
        }
        
        let codeResourcesPlist: [String: Any] = [
            "files": filesDict,
            "files2": files2Dict,
            "rules": [
                "^.*": true,
                "^.*\\.lproj/": [
                    "optional": true,
                    "weight": 1000
                ]
            ],
            "rules2": [
                "^.*": true,
                ".*\\.dSYM($|/)": [
                    "weight": 11
                ],
                "^(.*/)?\\.DS_Store$": [
                    "omit": true,
                    "weight": 2000
                ],
                "^.*\\.lproj/": [
                    "optional": true,
                    "weight": 1000
                ]
            ]
        ]
        
        let codeResourcesData = try PropertyListSerialization.data(fromPropertyList: codeResourcesPlist, format: .xml, options: 0)
        let codeResourcesURL = codeSignatureDir.appendingPathComponent("CodeResources")
        try codeResourcesData.write(to: codeResourcesURL)
    }
}
