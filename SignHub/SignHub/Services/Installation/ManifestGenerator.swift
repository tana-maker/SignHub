//
//  ManifestGenerator.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// Generates wireless Apple OTA installation XML manifest property list (manifest.plist)
public final class ManifestGenerator {
    public static let shared = ManifestGenerator()
    
    private init() {}
    
    /// Generates XML data for an itms-services manifest
    /// - Parameters:
    ///   - ipaDownloadURL: Full HTTPS URL to the signed IPA
    ///   - bundleIdentifier: App bundle ID
    ///   - bundleVersion: App version
    ///   - title: App title to display in iOS install confirmation prompt
    /// - Returns: XML UTF-8 encoded Data
    public func generateManifestData(
        ipaDownloadURL: URL,
        bundleIdentifier: String,
        bundleVersion: String,
        title: String
    ) throws -> Data {
        let manifestDict: [String: Any] = [
            "items": [
                [
                    "assets": [
                        [
                            "kind": "software-package",
                            "url": ipaDownloadURL.absoluteString
                        ]
                    ],
                    "metadata": [
                        "bundle-identifier": bundleIdentifier,
                        "bundle-version": bundleVersion,
                        "kind": "software",
                        "title": title
                    ]
                ]
            ]
        ]
        
        return try PropertyListSerialization.data(
            fromPropertyList: manifestDict,
            format: .xml,
            options: 0
        )
    }
}
