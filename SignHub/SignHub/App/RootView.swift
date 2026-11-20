//
//  RootView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import LocalAuthentication

/// Root container dynamically adjusting between iPhone and iPad, managing Face ID authentication and toast messages
public struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isAuthenticating: Bool = false
    
    public var body: some View {
        ZStack {
            if appState.isBiometricLockEnabled && !appState.isUnlocked {
                // Biometric Lock Screen
                biometricLockView
                    .transition(.opacity)
            } else {
                // Adaptive Main Application
                Group {
                    if horizontalSizeClass == .regular {
                        SidebarNavigation()
                    } else {
                        TabNavigation()
                    }
                }
                .transition(.opacity)
            }
            
            // Floating Global Toast Banner
            VStack {
                if let toast = appState.activeToast {
                    ToastBannerView(toast: toast) {
                        withAnimation {
                            appState.activeToast = nil
                        }
                    }
                    .padding(.top, 8)
                }
                Spacer()
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.activeToast)
        }
        .preferredColorScheme(appState.preferredColorScheme)
        .tint(appState.currentAccentColor)
        .onAppear {
            if appState.isBiometricLockEnabled && !appState.isUnlocked {
                authenticateUser()
            }
        }
        .sheet(isPresented: $appState.isPresentingSigningFlow) {
            if let file = appState.pendingSigningFileItem {
                SigningFlowView(sourceFile: file)
            }
        }
        .sheet(isPresented: $appState.isPresentingInstallProgress) {
            if let url = appState.pendingInstallPackageURL {
                InstallProgressSheet(
                    signedIPAURL: url,
                    appName: appState.pendingInstallAppName
                )
            }
        }
    }
    
    // MARK: - Face ID Lock Overlay
    
    private var biometricLockView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 72))
                .foregroundColor(appState.currentAccentColor)
                .padding(.bottom, 8)
            
            Text("SignHub is Locked")
                .font(.system(size: 26, weight: .bold))
            
            Text("Unlock with Face ID or Passcode to access your certificates and applications.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button {
                authenticateUser()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "faceid")
                        .font(.system(size: 20))
                    Text("Unlock SignHub")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(appState.currentAccentColor)
                )
                .padding(.horizontal, 32)
            }
            .minTapTarget()
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
    
    private func authenticateUser() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authenticate to unlock your SignHub IPA library."
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    self.isAuthenticating = false
                    if success {
                        HapticManager.shared.notification(.success)
                        withAnimation {
                            appState.isUnlocked = true
                        }
                    } else {
                        HapticManager.shared.notification(.error)
                    }
                }
            }
        } else {
            isAuthenticating = false
            withAnimation {
                appState.isUnlocked = true
            }
        }
    }
}
