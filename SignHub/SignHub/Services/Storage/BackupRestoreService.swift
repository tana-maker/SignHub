//
//  BackupRestoreService.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation
import CryptoKit

/// Encrypts and exports / imports app configurations, sources, and certificates
public final class BackupRestoreService {
    public static let shared = BackupRestoreService()
    
    public enum BackupError: LocalizedError {
        case encryptionFailed
        case decryptionFailed
        case invalidPassword
        
        public var errorDescription: String? {
            switch self {
            case .encryptionFailed: return "Failed to encrypt backup package."
            case .decryptionFailed: return "Failed to decrypt backup. Incorrect password or corrupted file."
            case .invalidPassword: return "Password cannot be empty."
            }
        }
    }
    
    private init() {}
    
    /// Exports all repositories and certificates into an encrypted .signhubbackup JSON bundle
    /// - Parameter passphrase: User-chosen encryption password
    /// - Returns: File URL to the saved backup file in temporary storage
    public func createBackup(passphrase: String) throws -> URL {
        guard !passphrase.isEmpty else { throw BackupError.invalidPassword }
        
        let sourcesData = UserDefaults.standard.data(forKey: "SignHub_User_Sources")
        let sources = (try? JSONDecoder().decode([SourceModel].self, from: sourcesData ?? Data())) ?? []
        
        let certsData = UserDefaults.standard.data(forKey: "SignHub_Stored_Certificates")
        let certs = (try? JSONDecoder().decode([CertificateModel].self, from: certsData ?? Data())) ?? []
        
        var encryptedP12s: [String: String] = [:]
        for cert in certs {
            let p12URL = FileManager.default.certificatesDirectory.appendingPathComponent(cert.p12FileName)
            if let p12Data = try? Data(contentsOf: p12URL) {
                let encrypted = try encryptData(p12Data, password: passphrase)
                encryptedP12s[cert.id] = encrypted.base64EncodedString()
            }
        }
        
        let package = BackupPackage(
            sources: sources,
            certificates: certs,
            p12EncryptedPayloads: encryptedP12s
        )
        
        let packageData = try JSONEncoder().encode(package)
        let backupURL = FileManager.default.temporaryDirectory.appendingPathComponent("SignHub_Backup_\(Int(Date().timeIntervalSince1970)).signhubbackup")
        try packageData.write(to: backupURL)
        return backupURL
    }
    
    /// Restores repositories and certificates from a .signhubbackup file
    /// - Parameters:
    ///   - backupURL: Path to .signhubbackup archive
    ///   - passphrase: Password used during backup creation
    public func restoreBackup(from backupURL: URL, passphrase: String) throws {
        let data = try Data(contentsOf: backupURL)
        let package = try JSONDecoder().decode(BackupPackage.self, from: data)
        
        // Restore Sources
        if let sourcesData = try? JSONEncoder().encode(package.sources) {
            UserDefaults.standard.set(sourcesData, forKey: "SignHub_User_Sources")
        }
        
        // Restore Certificates and Decrypt P12s
        for cert in package.certificates {
            if let encryptedBase64 = package.p12EncryptedPayloads[cert.id],
               let cipherData = Data(base64Encoded: encryptedBase64) {
                if let decryptedP12 = try? decryptData(cipherData, password: passphrase) {
                    let p12URL = FileManager.default.certificatesDirectory.appendingPathComponent(cert.p12FileName)
                    try? decryptedP12.write(to: p12URL)
                }
            }
        }
        
        if let certsData = try? JSONEncoder().encode(package.certificates) {
            UserDefaults.standard.set(certsData, forKey: "SignHub_Stored_Certificates")
        }
    }
    
    private func encryptData(_ data: Data, password: String) throws -> Data {
        guard let passData = password.data(using: .utf8) else { throw BackupError.invalidPassword }
        let key = SymmetricKey(data: passData.sha256)
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else { throw BackupError.encryptionFailed }
        return combined
    }
    
    private func decryptData(_ cipherData: Data, password: String) throws -> Data {
        guard let passData = password.data(using: .utf8) else { throw BackupError.invalidPassword }
        let key = SymmetricKey(data: passData.sha256)
        let sealedBox = try AES.GCM.SealedBox(combined: cipherData)
        return try AES.GCM.open(sealedBox, using: key)
    }
}
