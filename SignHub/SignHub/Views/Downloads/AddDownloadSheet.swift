//
//  AddDownloadSheet.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct AddDownloadSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var urlString: String = ""
    @State private var appName: String = ""
    @EnvironmentObject private var appState: AppState
    
    var onAdd: (URL, String) -> Void
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://example.com/app.ipa", text: $urlString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("App Name (Optional)", text: $appName)
                } header: {
                    Text("Download Details")
                } footer: {
                    Text("Enter a direct link to an IPA file. Background download will keep downloading even if you leave the app.")
                }
            }
            .navigationTitle("Add Download")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Download") {
                        startDownload()
                    }
                    .font(.headline)
                    .disabled(urlString.isEmpty)
                }
            }
        }
    }
    
    private func startDownload() {
        var clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.lowercased().hasPrefix("http://") && !clean.lowercased().hasPrefix("https://") {
            clean = "https://\(clean)"
        }
        guard let url = URL(string: clean) else { return }
        let finalName = appName.trimmingCharacters(in: .whitespaces).isEmpty
            ? url.deletingPathExtension().lastPathComponent
            : appName
        
        onAdd(url, finalName)
        dismiss()
    }
}
