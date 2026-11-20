//
//  BackupPackage.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// Encrypted backup package containing user repositories, certificates, and preferences
public struct BackupPackage: Codable {
    public let version: Int
    public let exportedAt: Date
    public let sources: [SourceModel]
    public let certificates: [CertificateModel]
    public let p12EncryptedPayloads: [String: String] // Certificate ID -> Base64 encrypted P12 with user passphrase
    public let settings: [String: String]
    
    public init(
        version: Int = 1,
        exportedAt: Date = Date(),
        sources: [SourceModel],
        certificates: [CertificateModel],
        p12EncryptedPayloads: [String: String] = [:],
        settings: [String: String] = [:]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.sources = sources
        self.certificates = certificates
        self.p12EncryptedPayloads = p12EncryptedPayloads
        self.settings = settings
    }
}
