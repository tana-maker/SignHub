//
//  SigningService.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation
import Combine

/// High-level orchestration service for signing IPAs using zsign or native fallback
public final class SigningService {
    public static let shared = SigningService()
    
    private init() {}
    
    /// Unpacks, customizes, signs, and packages an IPA
    /// - Parameters:
    ///   - sourceIPAURL: Path to original .ipa file
    ///   - certificate: The CertificateModel chosen by user
    ///   - options: Customization options
    ///   - logHandler: Streaming callback for real-time console output
    /// - Returns: URL of the final signed .ipa
    public func signIPA(
        sourceIPAURL: URL,
        certificate: CertificateModel,
        options: SigningOptions,
        logHandler: @escaping (SigningLogEntry) -> Void
    ) async throws -> URL {
        
        func log(_ message: String, _ level: LogLevel = .info) {
            logHandler(SigningLogEntry(level: level, message: message))
        }
        
        log("=== Starting Code Signing Session ===", .info)
        log("Source IPA: \(sourceIPAURL.lastPathComponent)", .info)
        log("Certificate: \(certificate.name) (\(certificate.teamName))", .info)
        
        // 1. Setup temporary workspace
        let workSessionID = UUID().uuidString
        let workDir = FileManager.default.signingWorkDirectory.appendingPathComponent(workSessionID)
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: workDir)
        }
        
        // 2. Unpack IPA archive
        log("Unpacking IPA archive...", .info)
        try await ZipArchiveService.shared.unzip(archiveAt: sourceIPAURL, to: workDir)
        log("Archive successfully unpacked.", .success)
        
        // Locate Payload/*.app
        let payloadDir = workDir.appendingPathComponent("Payload")
        guard let appBundleURL = try? FileManager.default.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension.lowercased() == "app" }) else {
            log("Error: Payload does not contain a valid .app bundle.", .error)
            throw NativeSigner.SignerError.appBundleNotFound
        }
        
        log("Found target application: \(appBundleURL.lastPathComponent)", .info)
        
        // 3. Retrieve Certificate Files
        let certsDir = FileManager.default.certificatesDirectory
        let p12URL = certsDir.appendingPathComponent(certificate.p12FileName)
        let provURL = certsDir.appendingPathComponent(certificate.provisionFileName)
        
        guard FileManager.default.fileExists(atPath: p12URL.path),
              FileManager.default.fileExists(atPath: provURL.path) else {
            log("Error: Certificate or mobileprovision files missing on disk.", .error)
            throw NSError(domain: "SignHub", code: -1, userInfo: [NSLocalizedDescriptionKey: "Certificate files missing."])
        }
        
        let p12Password = KeychainService.shared.getPassword(forAccount: certificate.p12KeychainKey) ?? ""
        let provData = try Data(contentsOf: provURL)
        
        // 4. Perform signing via NativeSigner
        try NativeSigner.shared.signBundle(
            appBundleURL: appBundleURL,
            certificate: certificate,
            provisioningProfileData: provData,
            options: options
        ) { msg, lvl in
            log(msg, level: lvl)
        }
        
        // 5. Repack signed IPA archive
        let safeAppName = options.customAppName.isEmpty
            ? appBundleURL.deletingPathExtension().lastPathComponent
            : options.customAppName.replacingOccurrences(of: "/", with: "-")
        
        let signedIPAFileName = "\(safeAppName)_signed_\(Int(Date().timeIntervalSince1970)).ipa"
        let finalSignedURL = FileManager.default.signedIPAsDirectory.appendingPathComponent(signedIPAFileName)
        
        log("Repacking signed application into: \(signedIPAFileName)...", .info)
        try await ZipArchiveService.shared.zip(directoryAt: workDir, to: finalSignedURL)
        log("=== IPA Code Signing Completed Successfully ===", .success)
        
        return finalSignedURL
    }
}
