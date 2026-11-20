//
//  SigningOptions.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// Customization options configured prior to signing an IPA
public struct SigningOptions: Codable, Equatable {
    public var customAppName: String
    public var customBundleIdentifier: String
    public var customVersion: String
    public var customBuildNumber: String
    public var customIconData: Data?
    public var injectedDylibFileNames: [String]
    public var removeAppExtensions: Bool
    public var removeSupportedDevices: Bool
    public var enableFileSharing: Bool
    public var enableiPadFullscreen: Bool
    public var compressionLevel: Int // 0 (fast) to 9 (maximum)
    
    public init(
        customAppName: String = "",
        customBundleIdentifier: String = "",
        customVersion: String = "",
        customBuildNumber: String = "",
        customIconData: Data? = nil,
        injectedDylibFileNames: [String] = [],
        removeAppExtensions: Bool = true,
        removeSupportedDevices: Bool = true,
        enableFileSharing: Bool = false,
        enableiPadFullscreen: Bool = true,
        compressionLevel: Int = 6
    ) {
        self.customAppName = customAppName
        self.customBundleIdentifier = customBundleIdentifier
        self.customVersion = customVersion
        self.customBuildNumber = customBuildNumber
        self.customIconData = customIconData
        self.injectedDylibFileNames = injectedDylibFileNames
        self.removeAppExtensions = removeAppExtensions
        self.removeSupportedDevices = removeSupportedDevices
        self.enableFileSharing = enableFileSharing
        self.enableiPadFullscreen = enableiPadFullscreen
        self.compressionLevel = compressionLevel
    }
}
