//
//  IPAMetadata.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// Inspection details extracted from an IPA's Info.plist, Mach-O binary, and embedded provisioning profile
public struct IPAMetadata: Codable, Hashable {
    public var appName: String
    public var bundleIdentifier: String
    public var version: String
    public var buildNumber: String
    public var minimumOSVersion: String
    public var supportedPlatforms: [String]
    public var appIconPNGData: Data?
    public var executableName: String
    public var frameworks: [String]
    public var appExtensions: [String]
    public var entitlements: [String: String]
    public var isEncrypted: Bool
    public var architecture: String
    
    public init(
        appName: String = "Unknown",
        bundleIdentifier: String = "com.unknown.app",
        version: String = "1.0",
        buildNumber: String = "1",
        minimumOSVersion: String = "14.0",
        supportedPlatforms: [String] = ["iPhoneOS"],
        appIconPNGData: Data? = nil,
        executableName: String = "",
        frameworks: [String] = [],
        appExtensions: [String] = [],
        entitlements: [String: String] = [:],
        isEncrypted: Bool = false,
        architecture: String = "arm64"
    ) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.buildNumber = buildNumber
        self.minimumOSVersion = minimumOSVersion
        self.supportedPlatforms = supportedPlatforms
        self.appIconPNGData = appIconPNGData
        self.executableName = executableName
        self.frameworks = frameworks
        self.appExtensions = appExtensions
        self.entitlements = entitlements
        self.isEncrypted = isEncrypted
        self.architecture = architecture
    }
}
