//
//  SettingsView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        List {
            // Certificate & Installed Apps Section
            Section(header: Text("Management")) {
                NavigationLink(destination: CertificateManagerView()) {
                    HStack {
                        Label {
                            Text(LocalizedStrings.certManagerTitle)
                                .font(.system(size: 16))
                        } icon: {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(appState.currentAccentColor)
                        }
                        
                        Spacer()
                        
                        if appState.expiringCertsCount > 0 {
                            Text("\(appState.expiringCertsCount) Expiring")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.orange))
                        }
                    }
                }
                
                NavigationLink(destination: SignedAppsView()) {
                    Label {
                        Text(LocalizedStrings.tabSigned)
                            .font(.system(size: 16))
                    } icon: {
                        Image(systemName: "app.badge.checkmark.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Security & Privacy
            Section(header: Text("Security")) {
                Toggle(isOn: $appState.isBiometricLockEnabled) {
                    Label {
                        Text("Face ID / Passcode Lock")
                            .font(.system(size: 16))
                    } icon: {
                        Image(systemName: "faceid")
                            .foregroundColor(.blue)
                    }
                }
                .onChange(of: appState.isBiometricLockEnabled) { enabled in
                    if enabled {
                        HapticManager.shared.notification(.success)
                        appState.showToast("Biometric Lock Enabled", type: .success)
                    }
                }
            }
            
            // Customization
            Section(header: Text("Customization")) {
                NavigationLink(destination: AppearanceView()) {
                    Label {
                        Text("Appearance & Accent")
                            .font(.system(size: 16))
                    } icon: {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(appState.currentAccentColor)
                    }
                }
                
                NavigationLink(destination: AdvancedSettingsView(viewModel: viewModel)) {
                    Label {
                        Text("Advanced Options")
                            .font(.system(size: 16))
                    } icon: {
                        Image(systemName: "gearshape.2.fill")
                            .foregroundColor(.indigo)
                    }
                }
            }
            
            // Storage & Maintenance
            Section(header: Text("Storage & Data")) {
                HStack {
                    Label {
                        Text("SignHub Storage")
                            .font(.system(size: 16))
                    } icon: {
                        Image(systemName: "internaldrive.fill")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(viewModel.diskUsageBytes.formattedByteCount)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Button(role: .destructive) {
                    viewModel.clearAllCache()
                } label: {
                    Label("Clear Cache & Temp Files", systemImage: "trash")
                        .foregroundColor(.red)
                }
                
                NavigationLink(destination: BackupRestoreView(viewModel: viewModel)) {
                    Label {
                        Text("Backup & Restore")
                            .font(.system(size: 16))
                    } icon: {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .foregroundColor(.teal)
                    }
                }
            }
            
            // Help & Diagnostics
            Section(header: Text("Help & Support")) {
                Button {
                    viewModel.isShowingOnboarding = true
                } label: {
                    Label("Quick Start Onboarding", systemImage: "sparkles")
                        .foregroundColor(.primary)
                }
                
                NavigationLink(destination: InstallGuideView()) {
                    Label {
                        Text("Installation Guide & Fixes")
                            .font(.system(size: 16))
                    } icon: {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                NavigationLink(destination: LogConsoleView()) {
                    Label {
                        Text("Diagnostic Logs")
                            .font(.system(size: 16))
                    } icon: {
                        Image(systemName: "terminal.fill")
                            .foregroundColor(.purple)
                    }
                }
                
                NavigationLink(destination: AboutView()) {
                    Label {
                        Text("About SignHub")
                            .font(.system(size: 16))
                    } icon: {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(LocalizedStrings.tabSettings)
        .sheet(isPresented: $viewModel.isShowingOnboarding) {
            OnboardingView()
        }
        .onAppear {
            viewModel.calculateDiskUsage()
        }
    }
}
