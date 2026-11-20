//
//  BackupRestoreView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import UniformTypeIdentifiers

public struct BackupRestoreView: View {
    @ObservedObject public var viewModel: SettingsViewModel
    @EnvironmentObject private var appState: AppState
    
    @State private var passphrase: String = ""
    @State private var restorePassphrase: String = ""
    @State private var isShowingRestorePicker: Bool = false
    @State private var isSharingBackup: Bool = false
    @State private var backupShareURL: URL?
    
    public var body: some View {
        Form {
            Section(header: Text("Export Encrypted Backup")) {
                SecureField("Backup Encryption Password", text: $passphrase)
                    .autocapitalization(.none)
                
                Button {
                    createAndShareBackup()
                } label: {
                    Label("Create & Export Backup", systemImage: "square.and.arrow.up")
                }
                .disabled(passphrase.count < 4)
            } footer: {
                Text("Backups are encrypted using AES-GCM-256 with your password. Contains all repositories, custom settings, and certificates.")
            }
            
            Section(header: Text("Restore Backup")) {
                SecureField("Decryption Password", text: $restorePassphrase)
                    .autocapitalization(.none)
                
                Button {
                    isShowingRestorePicker = true
                } label: {
                    Label("Select .signhubbackup File", systemImage: "arrow.down.doc")
                }
                .disabled(restorePassphrase.isEmpty)
            }
        }
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isShowingRestorePicker,
            allowedContentTypes: [.item]
        ) { result in
            if case .success(let url) = result {
                let _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    try BackupRestoreService.shared.restoreBackup(from: url, passphrase: restorePassphrase)
                    HapticManager.shared.notification(.success)
                    appState.showToast("Backup restored successfully!", type: .success)
                } catch {
                    appState.showToast("Failed restoring: \(error.localizedDescription)", type: .error)
                }
            }
        }
        .sheet(isPresented: $isSharingBackup) {
            if let url = backupShareURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func createAndShareBackup() {
        do {
            let url = try BackupRestoreService.shared.createBackup(passphrase: passphrase)
            self.backupShareURL = url
            self.isSharingBackup = true
            passphrase = ""
        } catch {
            appState.showToast(error.localizedDescription, type: .error)
        }
    }
}
