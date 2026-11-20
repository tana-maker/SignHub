//
//  SigningOptionsView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import PhotosUI

public struct SigningOptionsView: View {
    @ObservedObject public var viewModel: SigningViewModel
    @EnvironmentObject private var appState: AppState
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    public var body: some View {
        Form {
            // Certificate Selector Section
            Section(header: Text("Signing Certificate")) {
                if viewModel.availableCertificates.isEmpty {
                    Text("No certificates found. Please import one in Settings.")
                        .foregroundColor(.red)
                        .font(.system(size: 13))
                } else {
                    Picker("Certificate", selection: $viewModel.selectedCertificate) {
                        ForEach(viewModel.availableCertificates) { cert in
                            Text(cert.name).tag(cert as CertificateModel?)
                        }
                    }
                }
            }
            
            // App Identity Customization
            Section(header: Text("App Customization")) {
                HStack {
                    Text("App Name")
                    Spacer()
                    TextField("Display Name", text: $viewModel.options.customAppName)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Bundle ID")
                    Spacer()
                    TextField("com.domain.app", text: $viewModel.options.customBundleIdentifier)
                        .multilineTextAlignment(.trailing)
                        .autocapitalization(.none)
                }
                
                HStack {
                    Text("Version")
                    Spacer()
                    TextField("1.0", text: $viewModel.options.customVersion)
                        .multilineTextAlignment(.trailing)
                }
                
                // Custom Icon Picker
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    HStack {
                        Text("Custom App Icon")
                            .foregroundColor(.primary)
                        Spacer()
                        if let iconData = viewModel.options.customIconData, let uiImg = UIImage(data: iconData) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Text("Choose from Photos")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { newItem in
                    Task { @MainActor in
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            viewModel.options.customIconData = data
                        }
                    }
                }
            }
            
            // Advanced Tweaks & Modifications
            Section(header: Text("Advanced Modifications")) {
                NavigationLink(destination: DylibInjectionView(options: $viewModel.options)) {
                    HStack {
                        Text(LocalizedStrings.signingDylibInject)
                        Spacer()
                        Text("\(viewModel.options.injectedDylibFileNames.count) Linked")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(LocalizedStrings.signingRemoveExtensions, isOn: $viewModel.options.removeAppExtensions)
                Toggle(LocalizedStrings.signingRemoveSupportedDevices, isOn: $viewModel.options.removeSupportedDevices)
                Toggle(LocalizedStrings.signingFileSharing, isOn: $viewModel.options.enableFileSharing)
                Toggle(LocalizedStrings.signingiPadFullscreen, isOn: $viewModel.options.enableiPadFullscreen)
            }
            
            // Start Button
            Section {
                Button {
                    HapticManager.shared.impact(.heavy)
                    viewModel.startSigning()
                } label: {
                    HStack {
                        Spacer()
                        Text(LocalizedStrings.signingStartButton)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(appState.currentAccentColor)
                .disabled(viewModel.selectedCertificate == nil)
            }
        }
    }
}
