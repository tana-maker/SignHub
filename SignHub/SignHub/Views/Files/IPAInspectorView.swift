//
//  IPAInspectorView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct IPAInspectorView: View {
    public let fileItem: FileItem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    @State private var metadata: IPAMetadata?
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    
    public var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Inspecting IPA binary & payload...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                } else if let meta = metadata {
                    List {
                        // Header Section
                        Section {
                            HStack(spacing: 16) {
                                if let iconData = meta.appIconPNGData, let uiImg = UIImage(data: iconData) {
                                    Image(uiImage: uiImg)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 64, height: 64)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(appState.currentAccentColor.opacity(0.15))
                                        Image(systemName: "shippingbox.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(appState.currentAccentColor)
                                    }
                                    .frame(width: 64, height: 64)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(meta.appName)
                                        .font(.system(size: 18, weight: .bold))
                                    Text(meta.bundleIdentifier)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    Text("Version \(meta.version) (\(meta.buildNumber))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        
                        // System Compatibility
                        Section(header: Text("System & Architecture")) {
                            LabeledContent("Minimum iOS", value: meta.minimumOSVersion)
                            LabeledContent("Architecture", value: meta.architecture)
                            LabeledContent("FairPlay DRM", value: meta.isEncrypted ? "Encrypted (Requires Decryption)" : "Decrypted / Clean")
                            LabeledContent("Supported Platforms", value: meta.supportedPlatforms.joined(separator: ", "))
                        }
                        
                        // Embedded Frameworks
                        Section(header: Text("Embedded Frameworks (\(meta.frameworks.count))")) {
                            if meta.frameworks.isEmpty {
                                Text("No embedded frameworks")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(meta.frameworks, id: \.self) { framework in
                                    HStack {
                                        Image(systemName: "shippingbox")
                                            .foregroundColor(.blue)
                                        Text(framework)
                                            .font(.system(size: 14))
                                    }
                                }
                            }
                        }
                        
                        // App Extensions (PlugIns)
                        Section(header: Text("App Extensions / PlugIns (\(meta.appExtensions.count))")) {
                            if meta.appExtensions.isEmpty {
                                Text("No app extensions found")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(meta.appExtensions, id: \.self) { ext in
                                    HStack {
                                        Image(systemName: "puzzlepiece.extension")
                                            .foregroundColor(.orange)
                                        Text(ext)
                                            .font(.system(size: 14))
                                    }
                                }
                            }
                        }
                        
                        // Entitlements
                        Section(header: Text("Entitlements")) {
                            if meta.entitlements.isEmpty {
                                Text("No embedded entitlements found")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(meta.entitlements.sorted(by: { $0.key < $1.key }), id: \.key) { key, val in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(key)
                                            .font(.system(size: 13, weight: .semibold))
                                        Text(val)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    EmptyStateView(
                        iconName: "exclamationmark.triangle",
                        title: "Inspection Failed",
                        subtitle: errorMessage ?? "Unable to read IPA structure.",
                        accentColor: .red
                    )
                }
            }
            .navigationTitle("IPA Inspector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                do {
                    self.metadata = try await IPAMetadataExtractor.shared.inspectIPA(at: fileItem.fileURL)
                } catch {
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }
}
