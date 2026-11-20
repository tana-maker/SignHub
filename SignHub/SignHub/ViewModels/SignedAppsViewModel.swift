//
//  SignedAppsViewModel.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import Combine

@MainActor
public final class SignedAppsViewModel: ObservableObject {
    public static let shared = SignedAppsViewModel()
    
    @Published public private(set) var installedApps: [InstalledAppModel] = []
    @Published public var searchText: String = ""
    @Published public var isResigning: Bool = false
    
    private let storageKey = "SignHub_Installed_Apps"
    
    public init() {
        loadInstalledApps()
    }
    
    public var filteredApps: [InstalledAppModel] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return installedApps
        }
        return installedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    public func recordInstalledApp(_ app: InstalledAppModel) {
        if let idx = installedApps.firstIndex(where: { $0.bundleIdentifier == app.bundleIdentifier }) {
            installedApps[idx] = app
        } else {
            installedApps.insert(app, at: 0)
        }
        saveInstalledApps()
        
        Task {
            await NotificationManager.shared.checkCertificatesAndNotify()
        }
    }
    
    public func removeApp(id: String) {
        guard let idx = installedApps.firstIndex(where: { $0.id == id }) else { return }
        let app = installedApps[idx]
        
        let signedURL = FileManager.default.signedIPAsDirectory.appendingPathComponent(app.signedIPAFileName)
        try? FileManager.default.removeItem(at: signedURL)
        
        installedApps.remove(at: idx)
        saveInstalledApps()
        HapticManager.shared.notification(.success)
    }
    
    public func reSignApp(_ app: InstalledAppModel) {
        // Find source IPA in ipas directory
        guard let sourceName = app.sourceIPAFileName else {
            AppState.shared.showToast("Original source IPA not found for resigning.", type: .error)
            return
        }
        
        let sourceURL = FileManager.default.ipasDirectory.appendingPathComponent(sourceName)
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            AppState.shared.showToast("Original IPA file was deleted.", type: .error)
            return
        }
        
        let fileItem = FileItem(
            id: sourceURL.lastPathComponent,
            fileURL: sourceURL,
            fileName: app.name,
            fileSize: 0,
            creationDate: Date()
        )
        
        AppState.shared.triggerSigning(for: fileItem)
    }
    
    private func saveInstalledApps() {
        if let data = try? JSONEncoder().encode(installedApps) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadInstalledApps() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([InstalledAppModel].self, from: data) {
            self.installedApps = saved
        }
    }
}
