//
//  ImportCertificateSheet.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

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
    
    private var detectedLocalFiles: (p12: URL?, prov: URL?) {
        let docs = FileManager.default.documentsDirectory
        let certsDir = FileManager.default.certificatesDirectory
        let allURLs = ((try? FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil)) ?? []) +
                      ((try? FileManager.default.contentsOfDirectory(at: certsDir, includingPropertiesForKeys: nil)) ?? [])
        
        let p12 = allURLs.first { ["p12", "pfx"].contains($0.pathExtension.lowercased()) }
        let prov = allURLs.first { $0.pathExtension.lowercased() == "mobileprovision" }
        return (p12, prov)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                if let p12 = detectedLocalFiles.p12, p12Data == nil || provData == nil {
                    Section {
                        Button {
                            handlePickedFile(url: p12)
                            if let prov = detectedLocalFiles.prov {
                                handlePickedFile(url: prov)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18))
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Auto-Detect in SignHub Folder")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text("Found: \(p12.lastPathComponent)\(detectedLocalFiles.prov != nil ? " & " + (detectedLocalFiles.prov?.lastPathComponent ?? "") : "")")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("Auto-Fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(appState.currentAccentColor)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderless)
                    } header: {
                        Text("Detected On Device")
                    } footer: {
                        Text("You can also copy certificate files into 'Files app > On My iPad > SignHub'.")
                    }
                }
                
                Section {
                    // Primary Browse Button
                    Button {
                        isShowingPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down.on.square.fill")
                                .font(.system(size: 20))
                                .foregroundColor(appState.currentAccentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Browse Files (.p12 / .mobileprovision)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("Select .p12, .mobileprovision, or both")
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
                            Text(p12FileName ?? "Select or drag .p12 file here")
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
                            Text(provFileName ?? "Select or drag .mobileprovision file here")
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
                } footer: {
                    Text("Tip: On iPad, you can also open Files side-by-side and drag & drop your files directly into this screen.")
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
            .sheet(isPresented: $isShowingPicker) {
                SystemDocumentPicker(
                    onPick: { urls in
                        isShowingPicker = false
                        for url in urls {
                            handlePickedFile(url: url)
                        }
                    },
                    onCancel: {
                        isShowingPicker = false
                    }
                )
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

// MARK: - UIKit Document Picker with asCopy: true

public struct SystemDocumentPicker: UIViewControllerRepresentable {
    public var onPick: ([URL]) -> Void
    public var onCancel: () -> Void
    
    public init(onPick: @escaping ([URL]) -> Void, onCancel: @escaping () -> Void = {}) {
        self.onPick = onPick
        self.onCancel = onCancel
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        var supportedTypes: [UTType] = [.data, .item, .content]
        if let pkcs = UTType("com.rsa.pkcs-12") {
            supportedTypes.append(pkcs)
        }
        if let p12 = UTType(filenameExtension: "p12") {
            supportedTypes.append(p12)
        }
        if let pfx = UTType(filenameExtension: "pfx") {
            supportedTypes.append(pfx)
        }
        if let prov = UTType(filenameExtension: "mobileprovision") {
            supportedTypes.append(prov)
        }
        if let appleProv = UTType("com.apple.mobileprovision") {
            supportedTypes.append(appleProv)
        }
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: SystemDocumentPicker
        
        init(_ parent: SystemDocumentPicker) {
            self.parent = parent
        }
        
        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onPick(urls)
        }
        
        public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onCancel()
        }
    }
}

