//
//  SourceParserTests.swift
//  SignHubTests
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import XCTest
@testable import SignHub

final class SourceParserTests: XCTestCase {
    
    func testAltStoreSourceParsing() throws {
        let json = """
        {
            "name": "AltStore Community",
            "identifier": "com.community.repo",
            "iconURL": "https://example.com/icon.png",
            "apps": [
                {
                    "name": "Delta",
                    "bundleIdentifier": "com.rileytestut.Delta",
                    "version": "1.5.0",
                    "downloadURL": "https://example.com/delta.ipa",
                    "localizedDescription": "Game emulator",
                    "size": 52428800
                }
            ]
        }
        """
        
        let data = try XCTUnwrap(json.data(using: .utf8))
        let sourceURL = try XCTUnwrap(URL(string: "https://example.com/repo.json"))
        
        let (source, apps) = try AltStoreSourceParser.shared.parse(data: data, sourceURL: sourceURL)
        
        XCTAssertEqual(source.name, "AltStore Community")
        XCTAssertEqual(source.identifier, "com.community.repo")
        XCTAssertEqual(source.format, .altStore)
        XCTAssertEqual(apps.count, 1)
        XCTAssertEqual(apps[0].name, "Delta")
        XCTAssertEqual(apps[0].bundleIdentifier, "com.rileytestut.Delta")
        XCTAssertEqual(apps[0].size, 52428800)
    }
    
    func testScarletSourceParsing() throws {
        let json = """
        {
            "META": {
                "repoName": "Scarlet Alpha",
                "repoIcon": "https://example.com/scarlet.png"
            },
            "ITEMS": [
                {
                    "name": "Kodi Media",
                    "bundleID": "org.xbmc.kodi-ios",
                    "version": "20.1",
                    "down": "https://example.com/kodi.ipa",
                    "dev": "Kodi Team"
                }
            ]
        }
        """
        
        let data = try XCTUnwrap(json.data(using: .utf8))
        let sourceURL = try XCTUnwrap(URL(string: "https://example.com/scarlet.json"))
        
        let (source, apps) = try ScarletSourceParser.shared.parse(data: data, sourceURL: sourceURL)
        
        XCTAssertEqual(source.name, "Scarlet Alpha")
        XCTAssertEqual(source.format, .scarlet)
        XCTAssertEqual(apps.count, 1)
        XCTAssertEqual(apps[0].name, "Kodi Media")
        XCTAssertEqual(apps[0].developerName, "Kodi Team")
    }
}
