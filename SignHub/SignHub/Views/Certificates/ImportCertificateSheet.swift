//
//  ImportCertificateSheet.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import UniformTypeIdentifiers

public struct ImportCertificateSheet: View {
    @ObservedObject public var viewModel: CertificateManagerViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    @State private var certName: String = ""
    @State private var password: String = ""
    @State private var p12FileName: String?
    @State private var p12Data: Data?
    @State private var provFileName: String?
    @State private var provData: Data?
    
    @State private var isShowingPicker: Bool = false
    @State private var isImporting: Bool = false
    @State private var errorMessage: String?
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Quick Import Both Pair
                    Button {
                        isShowingPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down.on.square.fill")
                                .font(.system(size: 18))
                                .foregroundColor(appState.currentAccentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Select Files (.p12 & .mobileprovision)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("Choose both files together or one by one")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderless)
                    
                    // P12 File Picker Row
                    HStack {
                        Image(systemName: p12Data != nil ? "checkmark.circle.fill" : "doc.badge.key")
                            .font(.system(size: 20))
                            .foregroundColor(p12Data != nil ? .green : appState.currentAccentColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(".p12 Certificate")
                                .font(.system(size: 15, weight: .semibold))
                            Text(p12FileName ?? "Tap to browse .p12 or .pfx file")
                                .font(.system(size: 13))
                                .foregroundColor(p12Data == nil ? .secondary : .green)
                        }
                        Spacer()
                        Button(p12Data == nil ? "Browse" : "Change") {
                            isShowingPicker = true
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .buttonStyle(.borderless)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isShowingPicker = true
                    }
                    
                    // Provision Picker Row
                    HStack {
                        Image(systemName: provData != nil ? "checkmark.circle.fill" : "doc.text.fill")
                            .font(.system(size: 20))
                            .foregroundColor(provData != nil ? .green : appState.currentAccentColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(".mobileprovision Profile")
                                .font(.system(size: 15, weight: .semibold))
                            Text(provFileName ?? "Tap to browse provisioning profile")
                                .font(.system(size: 13))
                                .foregroundColor(provData == nil ? .secondary : .green)
                        }
                        Spacer()
                        Button(provData == nil ? "Browse" : "Change") {
                            isShowingPicker = true
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .buttonStyle(.borderless)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isShowingPicker = true
                    }
                } header: {
                    Text("Certificate Files")
                }
                
                Section {
                    SecureField("P12 Password", text: $password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Nickname (Optional)", text: $certName)
                } header: {
                    Text("Security & Details")
                } footer: {
                    Text("Your password is saved securely in the iOS Keychain and never sent to external servers.")
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Import Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        performImport()
                    } label: {
                        if isImporting {
                            ProgressView()
                        } else {
                            Text("Import")
                                .font(.headline)
                        }
                    }
                    .disabled(p12Data == nil || provData == nil || isImporting)
                }
            }
            .fileImporter(
                isPresented: $isShowingPicker,
                allowedContentTypes: [
                    .data,
                    .item,
                    .content,
                    UTType(filenameExtension: "p12") ?? .data,
                    UTType(filenameExtension: "pfx") ?? .data,
                    UTType(filenameExtension: "mobileprovision") ?? .data,
                    UTType("com.rsa.pkcs-12") ?? .data,
                    UTType("com.apple.mobileprovision") ?? .data
                ],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    for url in urls {
                        handlePickedFile(url: url)
                    }
                }
            }
        }
    }
    
    private func handlePickedFile(url: URL) {
        let _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return }
        let ext = url.pathExtension.lowercased()
        if ext == "p12" || ext == "pfx" {
            self.p12Data = data
            self.p12FileName = url.lastPathComponent
        } else if ext == "mobileprovision" {
            self.provData = data
            self.provFileName = url.lastPathComponent
        } else {
            if url.lastPathComponent.lowercased().contains("provision") {
                self.provData = data
                self.provFileName = url.lastPathComponent
            } else {
                self.p12Data = data
                self.p12FileName = url.lastPathComponent
            }
        }
    }
    
    private func performImport() {
        guard let p12 = p12Data, let prov = provData else { return }
        isImporting = true
        errorMessage = nil
        
        do {
            try viewModel.importCertificate(
                name: certName,
                p12Data: p12,
                provisionData: prov,
                password: password
            )
            dismiss()
        } catch {
            self.errorMessage = error.localizedDescription
            self.isImporting = false
            HapticManager.shared.notification(.error)
        }
    }
}
