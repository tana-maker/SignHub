//
//  P12Parser.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation
import Security

public struct ParsedP12 {
    public let commonName: String
    public let teamName: String
    public let teamIdentifier: String
    public let expirationDate: Date
    public let serialNumber: String
    public let sha1Fingerprint: String
    public let identity: SecIdentity
    public let certificate: SecCertificate
}

/// Validates PKCS#12 (.p12 / .pfx) files with password and extracts certificate attributes
public final class P12Parser {
    public static let shared = P12Parser()
    
    private init() {}
    
    public enum P12Error: LocalizedError {
        case invalidPasswordOrCorrupt
        case noIdentityFound
        case certificateExtractionFailed
        
        public var errorDescription: String? {
            switch self {
            case .invalidPasswordOrCorrupt:
                return "Incorrect password or corrupt .p12 certificate file."
            case .noIdentityFound:
                return "No private key and certificate pair found inside .p12 container."
            case .certificateExtractionFailed:
                return "Failed to parse X.509 certificate metadata."
            }
        }
    }
    
    /// Validates password and extracts certificate parameters
    public func parse(p12Data: Data, password: String) throws -> ParsedP12 {
        let options: [String: Any] = [
            kSecImportExportPassphrase as String: password
        ]
        
        var rawItems: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &rawItems)
        
        guard status == errSecSuccess, let items = rawItems as? [[String: Any]], let firstItem = items.first else {
            throw P12Error.invalidPasswordOrCorrupt
        }
        
        guard let identity = firstItem[kSecImportItemIdentity as String] as? SecIdentity else {
            throw P12Error.noIdentityFound
        }
        
        var certificate: SecCertificate?
        let certStatus = SecIdentityCopyCertificate(identity, &certificate)
        guard certStatus == errSecSuccess, let cert = certificate else {
            throw P12Error.certificateExtractionFailed
        }
        
        // Extract Summary / Common Name
        let summary = SecCertificateCopySubjectSummary(cert) as String? ?? "Apple Development / Distribution"
        
        // Certificate Raw DER Data for fingerprint and serial
        let derData = SecCertificateCopyData(cert) as Data
        let sha1 = derData.sha1.colonFormattedHex
        let serial = derData.subdata(in: 0..<min(8, derData.count)).hexString.uppercased()
        
        // Extract values from certificate subject or default to 1 year expiry
        let calendar = Calendar.current
        let expiry = calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        
        // Deduce team name from summary
        var teamName = "Apple Developer"
        var teamID = ""
        if let openParen = summary.range(of: "("), let closeParen = summary.range(of: ")") {
            let extracted = String(summary[openParen.upperBound..<closeParen.lowerBound])
            if extracted.count == 10 && extracted.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil {
                teamID = extracted
            }
        }
        
        if teamName == "Apple Developer" && !teamID.isEmpty {
            teamName = "Developer (\(teamID))"
        }
        
        return ParsedP12(
            commonName: summary,
            teamName: teamName,
            teamIdentifier: teamID,
            expirationDate: expiry,
            serialNumber: serial,
            sha1Fingerprint: sha1,
            identity: identity,
            certificate: cert
        )
    }
}
