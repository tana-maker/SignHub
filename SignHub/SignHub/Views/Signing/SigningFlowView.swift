//
//  SigningFlowView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct SigningFlowView: View {
    public let sourceFile: FileItem
    @StateObject private var viewModel: SigningViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    public init(sourceFile: FileItem) {
        self.sourceFile = sourceFile
        _viewModel = StateObject(wrappedValue: SigningViewModel(sourceFile: sourceFile))
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                switch viewModel.stage {
                case .options:
                    SigningOptionsView(viewModel: viewModel)
                case .signing:
                    SigningConsoleView(viewModel: viewModel)
                case .completed:
                    signingSuccessView
                case .failed:
                    signingFailureView
                }
            }
            .navigationTitle(LocalizedStrings.signingTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.stage != .signing {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Completed Screen
    
    private var signingSuccessView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.statusValid.opacity(0.15))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color.statusValid)
            }
            
            Text("Signing Complete!")
                .font(.system(size: 24, weight: .bold))
            
            Text("Your IPA has been customized, sealed, and signed with \(viewModel.selectedCertificate?.name ?? "your certificate").")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            VStack(spacing: 12) {
                // Install Immediately Action
                Button {
                    dismiss()
                    if let url = viewModel.signedIPAURL {
                        appState.pendingInstallPackageURL = url
                        appState.pendingInstallAppName = viewModel.options.customAppName.isEmpty ? viewModel.sourceFile.fileName : viewModel.options.customAppName
                        appState.isPresentingInstallProgress = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.app.fill")
                        Text("Install On This Device")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(appState.currentAccentColor))
                }
                .minTapTarget()
                
                // Done / Keep File
                Button {
                    dismiss()
                    appState.showToast("Signed IPA saved in Library", type: .success)
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Failed Screen
    
    private var signingFailureView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.statusExpired.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Color.statusExpired)
            }
            
            Text("Signing Failed")
                .font(.system(size: 22, weight: .bold))
            
            Text(viewModel.errorMessage ?? "An unknown error occurred during code signing.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            Button("Retry") {
                viewModel.stage = .options
            }
            .font(.headline)
            .padding(.bottom, 24)
        }
    }
}
