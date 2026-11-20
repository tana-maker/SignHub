//
//  SettingsViewModel.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import Combine

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var diskUsageBytes: Int64 = 0
    @Published public var isClearingCache: Bool = false
    @Published public var isShowingExportBackup: Bool = false
    @Published public var isShowingImportBackup: Bool = false
    @Published public var backupPassphrase: String = ""
    @Published public var backupFileURL: URL?
    @Published public var isShowingOnboarding: Bool = false
    @Published public var isShowingLogConsole: Bool = false
    
    @AppStorage("localServerPort") public var localServerPort: Int = 8088
    @AppStorage("cleanWorkDirAfterSign") public var cleanWorkDirAfterSign: Bool = true
    @AppStorage("enablePushNotifications") public var enablePushNotifications: Bool = true
    
    public init() {
        calculateDiskUsage()
    }
    
    public func calculateDiskUsage() {
        let fm = FileManager.default
        let ipasSize = fm.allocatedSizeOfDirectory(at: fm.ipasDirectory)
        let signedSize = fm.allocatedSizeOfDirectory(at: fm.signedIPAsDirectory)
        let cacheSize = fm.allocatedSizeOfDirectory(at: fm.cachesDirectory)
        self.diskUsageBytes = ipasSize + signedSize + cacheSize
    }
    
    public func clearAllCache() {
        isClearingCache = true
        let fm = FileManager.default
        fm.clearContents(of: fm.cachesDirectory)
        fm.clearContents(of: fm.signingWorkDirectory)
        calculateDiskUsage()
        isClearingCache = false
        HapticManager.shared.notification(.success)
        AppState.shared.showToast("Cache and temporary files cleared.", type: .success)
    }
    
    public func exportBackup() {
        do {
            let url = try BackupRestoreService.shared.createBackup(passphrase: backupPassphrase)
            self.backupFileURL = url
            self.isShowingExportBackup = true
            HapticManager.shared.notification(.success)
        } catch {
            AppState.shared.showToast(error.localizedDescription, type: .error)
        }
    }
}
