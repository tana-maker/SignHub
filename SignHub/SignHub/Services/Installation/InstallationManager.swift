//
//  InstallationManager.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import Combine

public enum InstallStage: String {
    case preparing = "Preparing package..."
    case startingServer = "Starting secure local server..."
    case generatingManifest = "Generating wireless OTA manifest..."
    case dispatching = "Dispatching to iOS installation daemon..."
    case awaitingPrompt = "Awaiting Home Screen installation prompt..."
    case completed = "Installation triggered successfully."
    case failed = "Installation error"
}

@MainActor
public final class InstallationManager: ObservableObject {
    public static let shared = InstallationManager()
    
    @Published public var currentStage: InstallStage = .preparing
    @Published public var progress: Double = 0.0
    @Published public var errorMessage: String?
    @Published public var isInstalling: Bool = false
    
    private init() {}
    
    /// Initiates local OTA installation
    /// - Parameters:
    ///   - ipaURL: URL of signed IPA package
    ///   - appName: Display title for the installation prompt
    public func installSignedIPA(at ipaURL: URL, appName: String) async {
        isInstalling = true
        errorMessage = nil
        progress = 0.1
        currentStage = .preparing
        
        do {
            try await Task.sleep(nanoseconds: 300_000_000)
            
            // 1. Inspect IPA for bundle ID and version
            progress = 0.3
            currentStage = .generatingManifest
            let metadata = (try? await IPAMetadataExtractor.shared.inspectIPA(at: ipaURL)) ?? IPAMetadata(appName: appName)
            
            // 2. Start local HTTPS server
            progress = 0.5
            currentStage = .startingServer
            let server = LocalHTTPSServer.shared
            
            let ipAddress = "127.0.0.1"
            let port: UInt16 = 8088
            guard let ipaDownloadURL = URL(string: "http://\(ipAddress):\(port)/package.ipa") else {
                throw NSError(domain: "SignHub", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid IPA download endpoint."])
            }
            
            let manifestData = try ManifestGenerator.shared.generateManifestData(
                ipaDownloadURL: ipaDownloadURL,
                bundleIdentifier: metadata.bundleIdentifier,
                bundleVersion: metadata.version,
                title: appName
            )
            
            let manifestURL = try server.startServer(
                signedIPAURL: ipaURL,
                manifestData: manifestData,
                port: port
            )
            
            // 3. Dispatch to itms-services://
            progress = 0.8
            currentStage = .dispatching
            
            guard let itmsURL = URL(string: "itms-services://?action=download-manifest&url=\(manifestURL.absoluteString)") else {
                throw NSError(domain: "SignHub", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid itms-services URL."])
            }
            
            try await Task.sleep(nanoseconds: 400_000_000)
            progress = 1.0
            currentStage = .awaitingPrompt
            
            #if canImport(UIKit)
            UIApplication.shared.open(itmsURL, options: [:]) { success in
                Task { @MainActor in
                    if success {
                        self.currentStage = .completed
                        HapticManager.shared.notification(.success)
                    } else {
                        self.currentStage = .failed
                        self.errorMessage = "iOS prevented launching the itms-services scheme."
                    }
                }
            }
            #endif
            
        } catch {
            currentStage = .failed
            errorMessage = error.localizedDescription
            HapticManager.shared.notification(.error)
        }
    }
}
