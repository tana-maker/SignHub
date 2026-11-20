//
//  AppState.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import Combine

/// Central observable state manager for global preferences and navigation
@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    // MARK: - Navigation
    @Published public var selectedTab: AppTab = .apps
    
    // MARK: - Appearance & Theming
    @AppStorage("userAccentColor") public var accentChoice: Color.AccentChoice = .sapphire
    @AppStorage("appearanceMode") public var appearanceMode: Int = 0 // 0: System, 1: Light, 2: Dark
    
    // MARK: - Security & Face ID
    @AppStorage("isBiometricLockEnabled") public var isBiometricLockEnabled: Bool = false
    @Published public var isUnlocked: Bool = false
    
    // MARK: - Global Toast Messaging
    @Published public var activeToast: ToastMessage?
    
    // MARK: - Badge Counters
    @Published public var activeDownloadsCount: Int = 0
    @Published public var expiringCertsCount: Int = 0
    
    // MARK: - Quick Launch State
    @Published public var pendingSigningFileItem: FileItem?
    @Published public var isPresentingSigningFlow: Bool = false
    @Published public var isPresentingInstallProgress: Bool = false
    @Published public var pendingInstallPackageURL: URL?
    @Published public var pendingInstallAppName: String = ""
    
    public var currentAccentColor: Color {
        accentChoice.color
    }
    
    public var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
    
    private init() {
        // If biometric lock is disabled, unlock immediately
        if !isBiometricLockEnabled {
            self.isUnlocked = true
        }
    }
    
    public func showToast(_ message: String, type: ToastType = .info, duration: Double = 3.0) {
        withAnimation(.spring()) {
            self.activeToast = ToastMessage(message: message, type: type, duration: duration)
        }
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if self.activeToast?.message == message {
                withAnimation(.spring()) {
                    self.activeToast = nil
                }
            }
        }
    }
    
    public func triggerSigning(for file: FileItem) {
        self.pendingSigningFileItem = file
        self.isPresentingSigningFlow = true
    }
}
