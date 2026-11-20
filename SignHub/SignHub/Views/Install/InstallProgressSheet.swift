//
//  InstallProgressSheet.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct InstallProgressSheet: View {
    public let signedIPAURL: URL
    public let appName: String
    
    @StateObject private var manager = InstallationManager.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var isShowingGuide: Bool = false
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Animated Progress Ring
                ProgressRing(
                    progress: manager.progress,
                    lineWidth: 6,
                    size: 88,
                    accentColor: appState.currentAccentColor,
                    isIndeterminate: manager.currentStage == .preparing || manager.currentStage == .startingServer
                )
                
                VStack(spacing: 8) {
                    Text(appName)
                        .font(.system(size: 22, weight: .bold))
                    
                    Text(manager.currentStage.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                if let error = manager.errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Instructions / Troubleshooting pill
                Button {
                    isShowingGuide = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle")
                        Text("Install Guide & Troubleshooting")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(appState.currentAccentColor)
                }
                .padding(.bottom, 8)
                
                Button {
                    LocalHTTPSServer.shared.stopServer()
                    dismiss()
                } label: {
                    Text(manager.currentStage == .completed ? "Done" : "Cancel")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(appState.currentAccentColor))
                        .padding(.horizontal, 24)
                }
                .minTapTarget()
                .padding(.bottom, 20)
            }
            .navigationTitle("Wireless Installation")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingGuide) {
                InstallGuideView()
            }
            .task {
                await manager.installSignedIPA(at: signedIPAURL, appName: appName)
            }
        }
    }
}
