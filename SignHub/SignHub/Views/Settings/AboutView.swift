//
//  AboutView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct AboutView: View {
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(appState.currentAccentColor.gradient)
                            .frame(width: 84, height: 84)
                            .shadow(color: appState.currentAccentColor.opacity(0.35), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "signature")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("SignHub")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Version 1.0.0 (Build 2026.11)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            
            Section(header: Text("Architecture & Engine")) {
                LabeledContent("Code Signer", value: "zsign C++ & Native Swift")
                LabeledContent("Install Engine", value: "Local TLS / itms-services")
                LabeledContent("Binary Engine", value: "Native Mach-O Parser")
                LabeledContent("Security", value: "Hardware Secure Enclave & Keychain")
            }
            
            Section(header: Text("Legal & Disclaimer")) {
                Text("SignHub is an on-device utility for developers and enthusiasts to sign and test iOS applications using their own legitimate Apple Developer credentials. SignHub does not host, distribute, or bundle copyrighted software or shared signing identities.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About SignHub")
        .navigationBarTitleDisplayMode(.inline)
    }
}
