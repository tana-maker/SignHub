//
//  SignHubApp.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import BackgroundTasks

@main
struct SignHubApp: App {
    @StateObject private var appState = AppState.shared
    @Environment(\.scenePhase) private var scenePhase
    
    // Background Refresh Task Identifier
    static let backgroundRefreshTaskID = "com.signhub.refresh"
    
    init() {
        // Register Background Tasks
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundRefreshTaskID,
            using: nil
        ) { task in
            guard let appRefreshTask = task as? BGAppRefreshTask else { return }
            Self.handleBackgroundRefresh(task: appRefreshTask)
        }
        
        // Setup initial default sources and directories
        setupInitialDirectories()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                if appState.isBiometricLockEnabled {
                    appState.isUnlocked = false
                }
                scheduleAppRefresh()
            }
        }
    }
    
    // MARK: - Initial Directory Creation
    
    private func setupInitialDirectories() {
        _ = FileManager.default.ipasDirectory
        _ = FileManager.default.signedIPAsDirectory
        _ = FileManager.default.certificatesDirectory
        _ = FileManager.default.signingWorkDirectory
    }
    
    // MARK: - Handle Incoming IPA or Repository URL
    
    private func handleIncomingURL(_ url: URL) {
        let ext = url.pathExtension.lowercased()
        if ext == "ipa" {
            let targetURL = FileManager.default.ipasDirectory.appendingPathComponent(url.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    try FileManager.default.removeItem(at: targetURL)
                }
                try FileManager.default.copyItem(at: url, to: targetURL)
                appState.showToast("Imported \(url.lastPathComponent)", type: .success)
                appState.selectedTab = .files
            } catch {
                appState.showToast("Failed to import file: \(error.localizedDescription)", type: .error)
            }
        } else if ext == "p12" || ext == "pfx" || ext == "mobileprovision" {
            let targetURL = FileManager.default.documentsDirectory.appendingPathComponent(url.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    try FileManager.default.removeItem(at: targetURL)
                }
                try FileManager.default.copyItem(at: url, to: targetURL)
                appState.showToast("Imported \(url.lastPathComponent)", type: .success)
                appState.selectedTab = .settings
            } catch {
                appState.showToast("Failed to import file: \(error.localizedDescription)", type: .error)
            }
        }
    }
    
    // MARK: - Background Refresh Scheduling
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundRefreshTaskID)
        // Check certificate expiry every 12 hours
        request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private static func handleBackgroundRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            // Check certificates expiry and schedule notifications if needed
            await NotificationManager.shared.checkCertificatesAndNotify()
            task.setTaskCompleted(success: true)
        }
    }
}
