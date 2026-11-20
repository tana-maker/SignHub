//
//  AdvancedSettingsView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct AdvancedSettingsView: View {
    @ObservedObject public var viewModel: SettingsViewModel
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        Form {
            Section(header: Text("Local Server Configuration")) {
                Stepper(value: $viewModel.localServerPort, in: 1024...65535, step: 1) {
                    HStack {
                        Text("HTTP Port")
                        Spacer()
                        Text("\(viewModel.localServerPort)")
                            .foregroundColor(.secondary)
                    }
                }
            } footer: {
                Text("Default is 8088. Change if another service on your device conflicts with this port.")
            }
            
            Section(header: Text("Temporary Files")) {
                Toggle("Auto-clean Workspace After Signing", isOn: $viewModel.cleanWorkDirAfterSign)
            } footer: {
                Text("Deletes temporary unpacked payload directories after packaging to conserve device flash storage.")
            }
            
            Section(header: Text("Background Refresh")) {
                Toggle("Certificate Expiry Checks", isOn: $viewModel.enablePushNotifications)
            } footer: {
                Text("Uses iOS background task scheduler to verify certificate validity and schedule warning notifications.")
            }
        }
        .navigationTitle("Advanced")
        .navigationBarTitleDisplayMode(.inline)
    }
}
