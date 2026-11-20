//
//  SourceDetailView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct SourceDetailView: View {
    public let source: SourceModel
    @State private var apps: [AppModel] = []
    @State private var isLoading: Bool = true
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonLoader(style: .appRow)
                    }
                }
                .padding()
            } else if apps.isEmpty {
                EmptyStateView(
                    iconName: "square.stack.3d.slash",
                    title: "No Applications",
                    subtitle: "This repository does not contain any available applications at the moment.",
                    accentColor: appState.currentAccentColor
                )
            } else {
                List(apps) { app in
                    NavigationLink(destination: AppDetailView(app: app)) {
                        HStack(spacing: 14) {
                            if let iconURL = app.iconURL {
                                AsyncImage(url: iconURL) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    Color.secondary.opacity(0.12)
                                }
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(appState.currentAccentColor.opacity(0.12))
                                    Image(systemName: "app.fill")
                                        .foregroundColor(appState.currentAccentColor)
                                        .font(.system(size: 22))
                                }
                                .frame(width: 52, height: 52)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(app.name)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(app.developerName ?? app.bundleIdentifier)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Text("v\(app.version) • \(app.size.formattedByteCount)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if let downloadURL = app.downloadURL {
                                Button {
                                    HapticManager.shared.impact(.medium)
                                    DownloadManager.shared.startDownload(
                                        url: downloadURL,
                                        appName: app.name,
                                        iconURL: app.iconURL
                                    )
                                    appState.showToast("Added \(app.name) to Downloads", type: .info)
                                } label: {
                                    Text("GET")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(appState.currentAccentColor)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(appState.currentAccentColor.opacity(0.15))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(source.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadApps()
        }
    }
    
    private func loadApps() async {
        isLoading = true
        do {
            let (_, fetchedApps) = try await SourceParserService.shared.fetchSource(from: source.url)
            self.apps = fetchedApps
        } catch {
            self.apps = []
        }
        isLoading = false
    }
}
