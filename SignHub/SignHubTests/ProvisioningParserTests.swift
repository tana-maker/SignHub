//
//  ProvisioningParserTests.swift
//  SignHubTests
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import XCTest
@testable import SignHub

final class ProvisioningParserTests: XCTestCase {
    
    func testExtractAndParseProvisioningProfile() throws {
        let mockPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Name</key>
            <string>iOS Team Provisioning Profile: com.example.test</string>
            <key>TeamName</key>
            <string>Acme Corp</string>
            <key>TeamIdentifier</key>
            <array>
                <string>ABCD1234EF</string>
            </array>
            <key>ProvisionedDevices</key>
            <array>
                <string>00008030-001A2B3C4D5E6F70</string>
                <string>00008101-00123456789ABCDE</string>
            </array>
            <key>Entitlements</key>
            <dict>
                <key>application-identifier</key>
                <string>ABCD1234EF.com.example.test</string>
                <key>get-task-allow</key>
                <true/>
            </dict>
        </dict>
        </plist>
        """
        
        var profileData = Data([0x30, 0x82, 0x05, 0x00]) // Mock ASN.1 CMS prefix
        let plistData = try XCTUnwrap(mockPlist.data(using: .utf8))
        profileData.append(plistData)
        profileData.append(Data([0x00, 0x00, 0x00, 0x00])) // Mock signature suffix
        
        let parsed = try ProvisioningParser.shared.parse(data: profileData)
        
        XCTAssertEqual(parsed.name, "iOS Team Provisioning Profile: com.example.test")
        XCTAssertEqual(parsed.teamName, "Acme Corp")
        XCTAssertEqual(parsed.teamIdentifier, "ABCD1234EF")
        XCTAssertEqual(parsed.provisionedUDIDs.count, 2)
        XCTAssertTrue(parsed.provisionedUDIDs.contains("00008030-001A2B3C4D5E6F70"))
        XCTAssertEqual(parsed.entitlements["application-identifier"], "ABCD1234EF.com.example.test")
        XCTAssertFalse(parsed.isEnterprise)
    }
}
