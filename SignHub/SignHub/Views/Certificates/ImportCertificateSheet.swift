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
    
    @State private var isShowingPairPicker: Bool = false
    @State private var isShowingP12Picker: Bool = false
    @State private var isShowingProvPicker: Bool = false
    @State private var isImporting: Bool = false
    @State private var errorMessage: String?
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Quick Import Both Pair
                    Button {
                        isShowingPairPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down.on.square.fill")
                                .foregroundColor(appState.currentAccentColor)
                            Text("Select Both Files Together (.p12 & .mobileprovision)")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // P12 File Picker
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(".p12 Certificate")
                                .font(.system(size: 15, weight: .semibold))
                            Text(p12FileName ?? "Select .p12 or .pfx file")
                                .font(.system(size: 13))
                                .foregroundColor(p12Data == nil ? .secondary : .primary)
                        }
                        Spacer()
                        Button {
                            isShowingP12Picker = true
                        } label: {
                            Text(p12Data == nil ? "Browse" : "Change")
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    
                    // Provision Picker
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(".mobileprovision Profile")
                                .font(.system(size: 15, weight: .semibold))
                            Text(provFileName ?? "Select provisioning profile")
                                .font(.system(size: 13))
                                .foregroundColor(provData == nil ? .secondary : .primary)
                        }
                        Spacer()
                        Button {
                            isShowingProvPicker = true
                        } label: {
                            Text(provData == nil ? "Browse" : "Change")
                                .font(.system(size: 13, weight: .semibold))
                        }
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
                isPresented: $isShowingPairPicker,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    for url in urls {
                        handlePickedFile(url: url)
                    }
                }
            }
            .fileImporter(
                isPresented: $isShowingP12Picker,
                allowedContentTypes: [.item]
            ) { result in
                if case .success(let url) = result {
                    handlePickedFile(url: url)
                }
            }
            .fileImporter(
                isPresented: $isShowingProvPicker,
                allowedContentTypes: [.item]
            ) { result in
                if case .success(let url) = result {
                    handlePickedFile(url: url)
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
