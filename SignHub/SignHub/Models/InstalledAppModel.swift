//
//  InstalledAppModel.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// Represents an app that was signed and installed via local OTA
public struct InstalledAppModel: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var bundleIdentifier: String
    public var version: String
    public var signedDate: Date
    public var expiryDate: Date
    public var certificateID: String
    public var certificateName: String
    public var iconData: Data?
    public var signedIPAFileName: String
    public var sourceIPAFileName: String?
    
    public var daysRemaining: Int {
        return expiryDate.daysRemaining
    }
    
    public var isExpiringSoon: Bool {
        return expiryDate.isExpiringSoon
    }
    
    public var isExpired: Bool {
        return expiryDate.isPast
    }
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        bundleIdentifier: String,
        version: String,
        signedDate: Date = Date(),
        expiryDate: Date,
        certificateID: String,
        certificateName: String,
        iconData: Data? = nil,
        signedIPAFileName: String,
        sourceIPAFileName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.signedDate = signedDate
        self.expiryDate = expiryDate
        self.certificateID = certificateID
        self.certificateName = certificateName
        self.iconData = iconData
        self.signedIPAFileName = signedIPAFileName
        self.sourceIPAFileName = sourceIPAFileName
    }
}
