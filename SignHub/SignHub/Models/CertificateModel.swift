//
//  CertificateModel.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// Status of an imported code signing certificate
public enum CertificateStatus: String, Codable {
    case valid = "Valid"
    case expiringSoon = "Expiring Soon"
    case expired = "Expired"
}

/// Represents an imported code signing certificate (.p12) paired with a provisioning profile (.mobileprovision)
public struct CertificateModel: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var teamName: String
    public var teamIdentifier: String
    public var commonName: String
    public var expiryDate: Date
    public var serialNumber: String?
    public var sha1Fingerprint: String?
    public var isDefault: Bool
    public var p12KeychainKey: String
    public var p12FileName: String
    public var provisionFileName: String
    public var provisionedUDIDs: [String]
    public var entitlements: [String: String]
    public var isEnterprise: Bool
    public var creationDate: Date
    
    public var status: CertificateStatus {
        if expiryDate < Date() {
            return .expired
        } else if expiryDate.isExpiringSoon {
            return .expiringSoon
        } else {
            return .valid
        }
    }
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        teamName: String,
        teamIdentifier: String,
        commonName: String,
        expiryDate: Date,
        serialNumber: String? = nil,
        sha1Fingerprint: String? = nil,
        isDefault: Bool = false,
        p12KeychainKey: String,
        p12FileName: String,
        provisionFileName: String,
        provisionedUDIDs: [String] = [],
        entitlements: [String: String] = [:],
        isEnterprise: Bool = false,
        creationDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.teamName = teamName
        self.teamIdentifier = teamIdentifier
        self.commonName = commonName
        self.expiryDate = expiryDate
        self.serialNumber = serialNumber
        self.sha1Fingerprint = sha1Fingerprint
        self.isDefault = isDefault
        self.p12KeychainKey = p12KeychainKey
        self.p12FileName = p12FileName
        self.provisionFileName = provisionFileName
        self.provisionedUDIDs = provisionedUDIDs
        self.entitlements = entitlements
        self.isEnterprise = isEnterprise
        self.creationDate = creationDate
    }
}
