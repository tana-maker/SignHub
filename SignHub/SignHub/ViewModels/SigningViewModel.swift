//
//  SigningViewModel.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import Combine

public enum SigningStage {
    case options
    case signing
    case completed
    case failed
}

@MainActor
public final class SigningViewModel: ObservableObject {
    public let sourceFile: FileItem
    
    @Published public var stage: SigningStage = .options
    @Published public var options = SigningOptions()
    @Published public var availableCertificates: [CertificateModel] = []
    @Published public var selectedCertificate: CertificateModel?
    @Published public var logs: [SigningLogEntry] = []
    @Published public var signedIPAURL: URL?
    @Published public var errorMessage: String?
    @Published public var isInjectingDylibs: Bool = false
    
    public init(sourceFile: FileItem) {
        self.sourceFile = sourceFile
        self.options.customAppName = sourceFile.fileName
        loadCertificates()
    }
    
    public func loadCertificates() {
        if let data = UserDefaults.standard.data(forKey: "SignHub_Stored_Certificates"),
           let list = try? JSONDecoder().decode([CertificateModel].self, from: data) {
            self.availableCertificates = list
            self.selectedCertificate = list.first(where: { $0.isDefault }) ?? list.first
        }
    }
    
    public func startSigning() {
        guard let cert = selectedCertificate else {
            errorMessage = "Please select or import a signing certificate first."
            return
        }
        
        stage = .signing
        logs.removeAll()
        
        Task {
            do {
                let finalURL = try await SigningService.shared.signIPA(
                    sourceIPAURL: sourceFile.fileURL,
                    certificate: cert,
                    options: options
                ) { [weak self] entry in
                    Task { @MainActor in
                        self?.logs.append(entry)
                    }
                }
                
                self.signedIPAURL = finalURL
                self.stage = .completed
                HapticManager.shared.notification(.success)
                
                // Track into installed apps list
                let installedApp = InstalledAppModel(
                    name: options.customAppName.isEmpty ? sourceFile.fileName : options.customAppName,
                    bundleIdentifier: options.customBundleIdentifier.isEmpty ? "com.signed.\(sourceFile.fileName.lowercased())" : options.customBundleIdentifier,
                    version: options.customVersion.isEmpty ? "1.0" : options.customVersion,
                    expiryDate: cert.expiryDate,
                    certificateID: cert.id,
                    certificateName: cert.name,
                    iconData: options.customIconData,
                    signedIPAFileName: finalURL.lastPathComponent,
                    sourceIPAFileName: sourceFile.fileURL.lastPathComponent
                )
                SignedAppsViewModel.shared.recordInstalledApp(installedApp)
                
            } catch {
                self.errorMessage = error.localizedDescription
                self.stage = .failed
                HapticManager.shared.notification(.error)
            }
        }
    }
}
