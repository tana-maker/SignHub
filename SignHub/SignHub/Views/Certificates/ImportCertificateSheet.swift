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
    
    private var localFiles: [URL] {
        let fm = FileManager.default
        let dirs = [fm.documentsDirectory, fm.certificatesDirectory]
        var list: [URL] = []
        for dir in dirs {
            if let items = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for item in items {
                    var isDir: ObjCBool = false
                    if fm.fileExists(atPath: item.path, isDirectory: &isDir), !isDir.boolValue {
                        if !list.contains(where: { $0.lastPathComponent == item.lastPathComponent }) {
                            list.append(item)
                        }
                    }
                }
            }
        }
        return list
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: In-App Direct File Picker (Bypasses iOS Document Picker entirely)
                Section {
                    if localFiles.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "folder.badge.questionmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(.orange)
                                Text("SignHub Folder (On My iPad)")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            Text("No certificate files in 'On My iPad > SignHub' yet.\n\nCopy or move your HSBC.p12 and HSBC.mobileprovision into:\n📁 Files app ➔ On My iPad ➔ SignHub\nThey will appear right here with a 1-tap 'Use' button!")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        ForEach(localFiles, id: \.self) { file in
                            let ext = file.pathExtension.lowercased()
                            let isProv = ext == "mobileprovision"
                            let isP12 = ["p12", "pfx"].contains(ext)
                            let isZip = ext == "zip"
                            let isSelected = isP12 ? (p12FileName == file.lastPathComponent) : (isProv ? (provFileName == file.lastPathComponent) : false)
                            
                            HStack {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : (isP12 ? "doc.badge.key" : (isProv ? "doc.text.fill" : "doc.zipper")))
                                    .font(.system(size: 18))
                                    .foregroundColor(isSelected ? .green : appState.currentAccentColor)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(file.lastPathComponent)
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(isP12 ? "Certificate (.p12)" : (isProv ? "Profile (.mobileprovision)" : (isZip ? "ZIP Package (Extracts both)" : ext.uppercased())))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(isSelected ? "Selected" : "Use") {
                                    handlePickedFile(url: file)
                                }
                                .font(.system(size: 13, weight: .bold))
                                .buttonStyle(.borderedProminent)
                                .tint(isSelected ? .green : appState.currentAccentColor)
                            }
                        }
                    }
                } header: {
                    Text("Direct From SignHub Folder (No Picker Needed)")
                } footer: {
                    Text("Files placed in 'On My iPad > SignHub' can be selected directly with zero iOS restrictions.")
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
        let isSec = url.startAccessingSecurityScopedResource()
        defer {
            if isSec {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let ext = url.pathExtension.lowercased()
        let name = url.lastPathComponent
        
        // Handle ZIP Archive
        if ext == "zip" {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            Task {
                try? await ZipArchiveService.shared.unzip(archiveAt: url, to: tempDir)
                if let subpaths = try? FileManager.default.subpathsOfDirectory(atPath: tempDir.path) {
                    for sub in subpaths {
                        let subURL = tempDir.appendingPathComponent(sub)
                        let subExt = subURL.pathExtension.lowercased()
                        if ["p12", "pfx"].contains(subExt) {
                            if let d = try? Data(contentsOf: subURL) {
                                await MainActor.run {
                                    self.p12Data = d
                                    self.p12FileName = subURL.lastPathComponent
                                }
                            }
                        } else if subExt == "mobileprovision" {
                            if let d = try? Data(contentsOf: subURL) {
                                await MainActor.run {
                                    self.provData = d
                                    self.provFileName = subURL.lastPathComponent
                                }
                            }
                        }
                    }
                }
            }
            return
        }
        
        // Coordinated read fallback
        var fileData = try? Data(contentsOf: url)
        if fileData == nil {
            let coordinator = NSFileCoordinator()
            coordinator.coordinate(readingItemAt: url, options: .withoutChanges, error: nil) { readURL in
                fileData = try? Data(contentsOf: readURL)
            }
        }
        
        guard let data = fileData else {
            self.errorMessage = "Could not read file: \(name)"
            return
        }
        
        if ext == "p12" || ext == "pfx" {
            self.p12Data = data
            self.p12FileName = name
        } else if ext == "mobileprovision" {
            self.provData = data
            self.provFileName = name
        } else {
            if name.lowercased().contains("provision") {
                self.provData = data
                self.provFileName = name
            } else {
                self.p12Data = data
                self.p12FileName = name
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
        let types = [
            "public.data",
            "public.item",
            "public.content",
            "com.rsa.pkcs-12",
            "com.apple.mobileprovision",
            "public.zip-archive"
        ]
        let picker = UIDocumentPickerViewController(documentTypes: types, in: .import)
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

