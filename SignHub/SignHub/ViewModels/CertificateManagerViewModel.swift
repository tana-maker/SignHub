//
//  CertificateManagerViewModel.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import Combine

@MainActor
public final class CertificateManagerViewModel: ObservableObject {
    @Published public var certificates: [CertificateModel] = []
    @Published public var isShowingImportSheet: Bool = false
    @Published public var selectedCertificate: CertificateModel?
    @Published public var errorMessage: String?
    
    private let storageKey = "SignHub_Stored_Certificates"
    
    public init() {
        loadCertificates()
    }
    
    public var defaultCertificate: CertificateModel? {
        certificates.first(where: { $0.isDefault }) ?? certificates.first
    }
    
    public func loadCertificates() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([CertificateModel].self, from: data) {
            self.certificates = saved
        }
        updateExpiringCount()
    }
    
    public func saveCertificates() {
        if let data = try? JSONEncoder().encode(certificates) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        updateExpiringCount()
    }
    
    public func setDefault(certificate: CertificateModel) {
        for i in 0..<certificates.count {
            certificates[i].isDefault = (certificates[i].id == certificate.id)
        }
        saveCertificates()
        HapticManager.shared.impact(.light)
        AppState.shared.showToast("Set default certificate: \(certificate.name)", type: .success)
    }
    
    public func deleteCertificate(at offsets: IndexSet) {
        for index in offsets {
            let cert = certificates[index]
            // Remove files
            let p12URL = FileManager.default.certificatesDirectory.appendingPathComponent(cert.p12FileName)
            let provURL = FileManager.default.certificatesDirectory.appendingPathComponent(cert.provisionFileName)
            try? FileManager.default.removeItem(at: p12URL)
            try? FileManager.default.removeItem(at: provURL)
            // Remove keychain entry
            KeychainService.shared.delete(forAccount: cert.p12KeychainKey)
        }
        certificates.remove(atOffsets: offsets)
        
        // Ensure one remains default if list not empty
        if !certificates.isEmpty && !certificates.contains(where: { $0.isDefault }) {
            certificates[0].isDefault = true
        }
        
        saveCertificates()
    }
    
    public func importCertificate(
        name: String,
        p12Data: Data,
        provisionData: Data,
        password: String
    ) throws {
        // 1. Validate P12 and password
        let parsedP12 = try P12Parser.shared.parse(p12Data: p12Data, password: password)
        
        // 2. Parse Provisioning Profile
        let parsedProv = try ProvisioningParser.shared.parse(data: provisionData)
        
        let certID = UUID().uuidString
        let p12FileName = "\(certID).p12"
        let provFileName = "\(certID).mobileprovision"
        
        let p12URL = FileManager.default.certificatesDirectory.appendingPathComponent(p12FileName)
        let provURL = FileManager.default.certificatesDirectory.appendingPathComponent(provFileName)
        
        try p12Data.write(to: p12URL)
        try provisionData.write(to: provURL)
        
        // 3. Save password to Keychain
        let keychainKey = "p12_key_\(certID)"
        _ = KeychainService.shared.savePassword(password, forAccount: keychainKey)
        
        let isFirst = certificates.isEmpty
        
        let cert = CertificateModel(
            id: certID,
            name: name.isEmpty ? parsedProv.name : name,
            teamName: parsedProv.teamName.isEmpty ? parsedP12.teamName : parsedProv.teamName,
            teamIdentifier: parsedProv.teamIdentifier,
            commonName: parsedP12.commonName,
            expiryDate: parsedProv.expirationDate,
            serialNumber: parsedP12.serialNumber,
            sha1Fingerprint: parsedP12.sha1Fingerprint,
            isDefault: isFirst,
            p12KeychainKey: keychainKey,
            p12FileName: p12FileName,
            provisionFileName: provFileName,
            provisionedUDIDs: parsedProv.provisionedUDIDs,
            entitlements: parsedProv.entitlements,
            isEnterprise: parsedProv.isEnterprise
        )
        
        certificates.append(cert)
        saveCertificates()
        HapticManager.shared.notification(.success)
        AppState.shared.showToast("Certificate imported: \(cert.name)", type: .success)
    }
    
    private func updateExpiringCount() {
        let count = certificates.filter { $0.status == .expiringSoon || $0.status == .expired }.count
        AppState.shared.expiringCertsCount = count
    }
}
