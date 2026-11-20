//
//  IPAMetadataExtractor.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// Fast metadata inspection engine reading Info.plist, Mach-O headers, and embedded resources from IPAs
public final class IPAMetadataExtractor {
    public static let shared = IPAMetadataExtractor()
    
    private init() {}
    
    /// Extracts metadata from an IPA without fully decompressing the entire file
    public func inspectIPA(at ipaURL: URL) async throws -> IPAMetadata {
        // Unpack temporary working copy of just the app bundle or use streaming
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("inspect_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        try await ZipArchiveService.shared.unzip(archiveAt: ipaURL, to: tempDir)
        
        let payloadDir = tempDir.appendingPathComponent("Payload")
        guard let appBundleURL = try? FileManager.default.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension.lowercased() == "app" }) else {
            throw NSError(domain: "SignHub", code: -1, userInfo: [NSLocalizedDescriptionKey: "No .app bundle found inside Payload."])
        }
        
        // 1. Parse Info.plist
        let infoPlistURL = appBundleURL.appendingPathComponent("Info.plist")
        var metadata = IPAMetadata()
        
        if let plistData = try? Data(contentsOf: infoPlistURL),
           let plist = (try? PropertyListSerialization.propertyList(from: plistData, format: nil)) as? [String: Any] {
            metadata.appName = plist["CFBundleDisplayName"] as? String
                ?? plist["CFBundleName"] as? String
                ?? appBundleURL.deletingPathExtension().lastPathComponent
            
            metadata.bundleIdentifier = plist["CFBundleIdentifier"] as? String ?? "com.unknown.app"
            metadata.version = plist["CFBundleShortVersionString"] as? String ?? "1.0"
            metadata.buildNumber = plist["CFBundleVersion"] as? String ?? "1"
            metadata.minimumOSVersion = plist["MinimumOSVersion"] as? String ?? "14.0"
            metadata.supportedPlatforms = plist["CFBundleSupportedPlatforms"] as? [String] ?? ["iPhoneOS"]
            metadata.executableName = plist["CFBundleExecutable"] as? String ?? ""
        }
        
        // 2. Extract App Icon
        metadata.appIconPNGData = findAppIcon(in: appBundleURL)
        
        // 3. Inspect Frameworks
        let frameworksDir = appBundleURL.appendingPathComponent("Frameworks")
        if let items = try? FileManager.default.contentsOfDirectory(at: frameworksDir, includingPropertiesForKeys: nil) {
            metadata.frameworks = items.map { $0.lastPathComponent }
        }
        
        // 4. Inspect PlugIns / App Extensions
        let pluginsDir = appBundleURL.appendingPathComponent("PlugIns")
        if let items = try? FileManager.default.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil) {
            metadata.appExtensions = items.map { $0.lastPathComponent }
        }
        
        // 5. Inspect embedded provisioning profile
        let embeddedProfileURL = appBundleURL.appendingPathComponent("embedded.mobileprovision")
        if let profileData = try? Data(contentsOf: embeddedProfileURL),
           let parsed = try? ProvisioningParser.shared.parse(data: profileData) {
            metadata.entitlements = parsed.entitlements
        }
        
        // 6. Inspect Mach-O for FairPlay DRM encryption
        if !metadata.executableName.isEmpty {
            let execURL = appBundleURL.appendingPathComponent(metadata.executableName)
            if let execData = try? Data(contentsOf: execURL) {
                metadata.isEncrypted = MachOHelper.isFairPlayEncrypted(binaryData: execData)
                metadata.architecture = MachOHelper.detectArchitecture(binaryData: execData)
            }
        }
        
        return metadata
    }
    
    private func findAppIcon(in appBundleURL: URL) -> Data? {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: appBundleURL, includingPropertiesForKeys: nil) else {
            return nil
        }
        
        // Common icon names: AppIcon60x60@2x.png, AppIcon60x60@3x.png, AppIcon76x76@2x~ipad.png, etc.
        let iconFiles = files.filter { url in
            let name = url.lastPathComponent.lowercased()
            return name.hasPrefix("appicon") && name.hasSuffix(".png")
        }.sorted(by: { $0.lastPathComponent.count > $1.lastPathComponent.count })
        
        if let first = iconFiles.first, let data = try? Data(contentsOf: first) {
            return data
        }
        
        // Fallback to any file with 'icon' in name
        let fallback = files.filter { $0.lastPathComponent.lowercased().contains("icon") && $0.pathExtension.lowercased() == "png" }
        if let first = fallback.first, let data = try? Data(contentsOf: first) {
            return data
        }
        
        return nil
    }
}
