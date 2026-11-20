//
//  AppDetailView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct AppDetailView: View {
    public let app: AppModel
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Top Header Card
                HStack(spacing: 16) {
                    if let iconURL = app.iconURL {
                        AsyncImage(url: iconURL) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Color.secondary.opacity(0.12)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(appState.currentAccentColor.opacity(0.14))
                            Image(systemName: "app.fill")
                                .font(.system(size: 38))
                                .foregroundColor(appState.currentAccentColor)
                        }
                        .frame(width: 80, height: 80)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(app.developerName ?? app.bundleIdentifier)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Button {
                            HapticManager.shared.impact(.heavy)
                            if let url = app.downloadURL {
                                DownloadManager.shared.startDownload(url: url, appName: app.name, iconURL: app.iconURL)
                                appState.showToast("Downloading \(app.name)", type: .info)
                            }
                        } label: {
                            Text(LocalizedStrings.actionGet)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(appState.currentAccentColor))
                        }
                        .padding(.top, 4)
                        .minTapTarget()
                    }
                    
                    Spacer()
                }
                .padding()
                .glassCard(cornerRadius: 22)
                
                // Metadata Bar
                HStack {
                    VStack(spacing: 4) {
                        Text("VERSION")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(app.version)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider().frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("SIZE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(app.size > 0 ? app.size.formattedByteCount : "--")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider().frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("COMPATIBILITY")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("iOS \(app.minimumOSVersion ?? "14.0")+")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .glassCard(cornerRadius: 18)
                
                // Description Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("About This App")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text(app.localizedDescription ?? "No description provided by repository developer.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding()
                .glassCard(cornerRadius: 18)
                
                // Information Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Information")
                        .font(.system(size: 18, weight: .bold))
                    
                    DetailInfoRow(title: "Bundle ID", value: app.bundleIdentifier)
                    DetailInfoRow(title: "Category", value: app.category ?? "Utilities")
                    if let releaseDate = app.releaseDate {
                        DetailInfoRow(title: "Updated", value: releaseDate.shortDateString)
                    }
                }
                .padding()
                .glassCard(cornerRadius: 18)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}
