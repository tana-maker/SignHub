//
//  SigningServiceTests.swift
//  SignHubTests
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import XCTest
@testable import SignHub

final class SigningServiceTests: XCTestCase {
    
    func testSigningOptionsDefaultValues() {
        let options = SigningOptions()
        XCTAssertEqual(options.customAppName, "")
        XCTAssertEqual(options.customBundleIdentifier, "")
        XCTAssertEqual(options.customVersion, "")
        XCTAssertTrue(options.removeAppExtensions)
        XCTAssertTrue(options.removeSupportedDevices)
        XCTAssertFalse(options.enableFileSharing)
        XCTAssertTrue(options.enableiPadFullscreen)
        XCTAssertEqual(options.compressionLevel, 6)
    }
    
    func testCertificateStatusCalculation() throws {
        let calendar = Calendar.current
        
        // 1. Future date (> 30 days) -> Valid
        let futureDate = try XCTUnwrap(calendar.date(byAdding: .day, value: 90, to: Date()))
        let validCert = CertificateModel(
            name: "Dev Cert",
            teamName: "Team A",
            teamIdentifier: "12345ABCDE",
            commonName: "Apple Development",
            expiryDate: futureDate,
            p12KeychainKey: "key_1",
            p12FileName: "cert.p12",
            provisionFileName: "profile.mobileprovision"
        )
        XCTAssertEqual(validCert.status, .valid)
        
        // 2. Expiring soon date (< 30 days) -> Expiring Soon
        let soonDate = try XCTUnwrap(calendar.date(byAdding: .day, value: 15, to: Date()))
        let expiringCert = CertificateModel(
            name: "Soon Cert",
            teamName: "Team B",
            teamIdentifier: "67890FGHIJ",
            commonName: "Apple Development",
            expiryDate: soonDate,
            p12KeychainKey: "key_2",
            p12FileName: "cert2.p12",
            provisionFileName: "profile2.mobileprovision"
        )
        XCTAssertEqual(expiringCert.status, .expiringSoon)
        
        // 3. Past date -> Expired
        let pastDate = try XCTUnwrap(calendar.date(byAdding: .day, value: -5, to: Date()))
        let expiredCert = CertificateModel(
            name: "Old Cert",
            teamName: "Team C",
            teamIdentifier: "ABCDE12345",
            commonName: "Apple Development",
            expiryDate: pastDate,
            p12KeychainKey: "key_3",
            p12FileName: "cert3.p12",
            provisionFileName: "profile3.mobileprovision"
        )
        XCTAssertEqual(expiredCert.status, .expired)
    }
}
