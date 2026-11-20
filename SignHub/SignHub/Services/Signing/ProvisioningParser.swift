//
//  ProvisioningParser.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

public struct ParsedProvisioningProfile {
    public let name: String
    public let teamName: String
    public let teamIdentifier: String
    public let creationDate: Date
    public let expirationDate: Date
    public let provisionedUDIDs: [String]
    public let entitlements: [String: String]
    public let isEnterprise: Bool
    public let rawEntitlementsPlist: [String: Any]
}

/// Parses Apple `.mobileprovision` files by extracting the XML Property List from the CMS/PKCS#7 signed container
public final class ProvisioningParser {
    public static let shared = ProvisioningParser()
    
    private init() {}
    
    public enum ProvisioningError: LocalizedError {
        case invalidProfile
        case xmlNotFound
        case parsingFailed(String)
        
        public var errorDescription: String? {
            switch self {
            case .invalidProfile: return "The mobileprovision file is corrupt or invalid."
            case .xmlNotFound: return "Could not locate embedded plist data inside mobileprovision."
            case .parsingFailed(let reason): return "Failed to parse provisioning profile: \(reason)"
            }
        }
    }
    
    /// Parses raw mobileprovision data into structured fields
    /// - Parameter data: Raw bytes of the .mobileprovision file
    /// - Returns: Parsed profile structure
    public func parse(data: Data) throws -> ParsedProvisioningProfile {
        // Mobileprovision files are signed CMS blobs. The XML plist begins with "<?xml" and ends with "</plist>"
        guard let xmlData = extractXML(from: data) else {
            throw ProvisioningError.xmlNotFound
        }
        
        var format = PropertyListSerialization.PropertyListFormat.xml
        guard let plist = try PropertyListSerialization.propertyList(
            from: xmlData,
            options: [],
            format: &format
        ) as? [String: Any] else {
            throw ProvisioningError.invalidProfile
        }
        
        let name = plist["Name"] as? String ?? "Unnamed Profile"
        let teamName = plist["TeamName"] as? String ?? "Unknown Team"
        let teamIDs = plist["TeamIdentifier"] as? [String] ?? []
        let teamID = teamIDs.first ?? ""
        let creationDate = plist["CreationDate"] as? Date ?? Date()
        let expirationDate = plist["ExpirationDate"] as? Date ?? Date()
        let provisionedDevices = plist["ProvisionedDevices"] as? [String] ?? []
        let rawEntitlements = plist["Entitlements"] as? [String: Any] ?? [:]
        
        // Enterprise (In-House) profiles do not list specific provisioned devices and have ProvisionsAllDevices = true
        let provisionsAllDevices = plist["ProvisionsAllDevices"] as? Bool ?? false
        let isEnterprise = provisionsAllDevices || provisionedDevices.isEmpty
        
        var entitlements: [String: String] = [:]
        for (key, val) in rawEntitlements {
            entitlements[key] = "\(val)"
        }
        
        return ParsedProvisioningProfile(
            name: name,
            teamName: teamName,
            teamIdentifier: teamID,
            creationDate: creationDate,
            expirationDate: expirationDate,
            provisionedUDIDs: provisionedDevices,
            entitlements: entitlements,
            isEnterprise: isEnterprise,
            rawEntitlementsPlist: rawEntitlements
        )
    }
    
    /// Scans for `<?xml` and `</plist>` markers to isolate the plist payload
    private func extractXML(from data: Data) -> Data? {
        guard let xmlStartMarker = "<?xml".data(using: .utf8),
              let xmlEndMarker = "</plist>".data(using: .utf8) else {
            return nil
        }
        
        guard let startRange = data.range(of: xmlStartMarker),
              let endRange = data.range(of: xmlEndMarker, options: .backwards, in: startRange.upperBound..<data.count) else {
            return nil
        }
        
        let fullRange = startRange.lowerBound..<endRange.upperBound
        return data.subdata(in: fullRange)
    }
}
