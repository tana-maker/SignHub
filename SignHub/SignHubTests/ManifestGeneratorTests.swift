//
//  ManifestGeneratorTests.swift
//  SignHubTests
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import XCTest
@testable import SignHub

final class ManifestGeneratorTests: XCTestCase {
    
    func testGenerateValidOTAInstallationManifest() throws {
        let downloadURL = try XCTUnwrap(URL(string: "https://127.0.0.1:8088/package.ipa"))
        let bundleID = "com.rileytestut.Delta"
        let version = "1.5.0"
        let title = "Delta Emulator"
        
        let manifestData = try ManifestGenerator.shared.generateManifestData(
            ipaDownloadURL: downloadURL,
            bundleIdentifier: bundleID,
            bundleVersion: version,
            title: title
        )
        
        XCTAssertFalse(manifestData.isEmpty)
        
        var format = PropertyListSerialization.PropertyListFormat.xml
        let plist = try PropertyListSerialization.propertyList(
            from: manifestData,
            options: [],
            format: &format
        ) as? [String: Any]
        
        XCTAssertNotNil(plist)
        let items = plist?["items"] as? [[String: Any]]
        XCTAssertEqual(items?.count, 1)
        
        let firstItem = items?.first
        let assets = firstItem?["assets"] as? [[String: Any]]
        let metadata = firstItem?["metadata"] as? [String: Any]
        
        XCTAssertEqual(assets?.first?["kind"] as? String, "software-package")
        XCTAssertEqual(assets?.first?["url"] as? String, downloadURL.absoluteString)
        XCTAssertEqual(metadata?["bundle-identifier"] as? String, bundleID)
        XCTAssertEqual(metadata?["bundle-version"] as? String, version)
        XCTAssertEqual(metadata?["title"] as? String, title)
    }
}
