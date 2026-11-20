//
//  InstallGuideView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct InstallGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("How Wireless Install Works")) {
                    StepRow(number: "1", title: "App Sign & Seal", desc: "SignHub signs the IPA with your developer certificate and embeds the provisioning profile.")
                    StepRow(number: "2", title: "Secure Local Host", desc: "A mini local HTTPS server hosts the manifest.plist and the signed IPA package on this device.")
                    StepRow(number: "3", title: "System Prompt", desc: "iOS opens itms-services and prompts: 'Install [App Name]?'. Tap Install.")
                    StepRow(number: "4", title: "Home Screen Download", desc: "The app will begin installing directly onto your Home Screen.")
                }
                
                Section(header: Text("Troubleshooting")) {
                    DisclosureGroup("Error: 'Unable to Verify App'") {
                        Text("On iOS 16+, go to Settings > General > VPN & Device Management > Tap your Developer App certificate > Tap 'Trust'. Also ensure Developer Mode is enabled in Settings > Privacy & Security > Developer Mode.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                    
                    DisclosureGroup("Error: 'Integrity Could Not Be Verified'") {
                        Text("This indicates the certificate has been revoked by Apple, or your device UDID is not listed in the provisioning profile. Ensure you are using an active certificate with your device registered.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                    
                    DisclosureGroup("Install Prompt Does Not Appear") {
                        Text("Keep SignHub open in the foreground while the prompt appears so the local web server remains active. If on Wi-Fi, ensure your network allows local loopback traffic.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Installation Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct StepRow: View {
    let number: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                Text(number)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
            }
            .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
