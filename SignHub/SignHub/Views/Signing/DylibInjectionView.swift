//
//  DylibInjectionView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import UniformTypeIdentifiers

public struct DylibInjectionView: View {
    @Binding public var options: SigningOptions
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    @State private var isShowingFilePicker: Bool = false
    
    public var body: some View {
        List {
            Section(header: Text("Injected Dylibs & Frameworks")) {
                if options.injectedDylibFileNames.isEmpty {
                    Text("No dylibs linked. Tap 'Add Dylib' to inject tweaks or libraries into this app.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                } else {
                    ForEach(options.injectedDylibFileNames, id: \.self) { dylib in
                        HStack {
                            Image(systemName: "shippingbox.fill")
                                .foregroundColor(appState.currentAccentColor)
                            Text(dylib)
                                .font(.system(size: 14))
                        }
                    }
                    .onDelete { indexSet in
                        options.injectedDylibFileNames.remove(atOffsets: indexSet)
                    }
                }
            }
            
            Section {
                Button {
                    isShowingFilePicker = true
                } label: {
                    Label("Add Dylib / Framework", systemImage: "plus")
                        .foregroundColor(appState.currentAccentColor)
                }
            } footer: {
                Text("Dylibs will be copied to the app's Frameworks folder and Mach-O load commands (LC_LOAD_DYLIB) will be injected with @executable_path/Frameworks.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Dylib Injection")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                for url in urls {
                    let _ = url.startAccessingSecurityScopedResource()
                    defer { url.stopAccessingSecurityScopedResource() }
                    let fileName = url.lastPathComponent
                    if !options.injectedDylibFileNames.contains(fileName) {
                        options.injectedDylibFileNames.append(fileName)
                    }
                }
            }
        }
    }
}
