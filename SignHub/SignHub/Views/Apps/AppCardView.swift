//
//  AppCardView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

/// List row presentation of an application
public struct AppCardRowItem: View {
    public let app: AppModel
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        HStack(spacing: 14) {
            // App Icon
            if let iconURL = app.iconURL {
                AsyncImage(url: iconURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color.secondary.opacity(0.12)
                }
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(appState.currentAccentColor.opacity(0.12))
                    Image(systemName: "app.fill")
                        .font(.system(size: 26))
                        .foregroundColor(appState.currentAccentColor)
                }
                .frame(width: 58, height: 58)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(app.developerName ?? app.bundleIdentifier)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("v\(app.version)")
                        .font(.system(size: 11, weight: .medium))
                    if app.size > 0 {
                        Text("•")
                        Text(app.size.formattedByteCount)
                            .font(.system(size: 11))
                    }
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // GET / Action Button with Progress Ring capability
            Button {
                HapticManager.shared.impact(.medium)
                if let url = app.downloadURL {
                    DownloadManager.shared.startDownload(url: url, appName: app.name, iconURL: app.iconURL)
                    appState.showToast("Downloading \(app.name)...", type: .info)
                }
            } label: {
                Text(LocalizedStrings.actionGet)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(appState.currentAccentColor)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(appState.currentAccentColor.opacity(0.14))
                    )
            }
            .buttonStyle(.plain)
            .minTapTarget()
        }
        .padding(12)
        .glassCard(cornerRadius: 18)
    }
}

/// Grid card presentation of an application
public struct AppCardGridItem: View {
    public let app: AppModel
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
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
                            .font(.system(size: 24))
                            .foregroundColor(appState.currentAccentColor)
                    }
                    .frame(width: 52, height: 52)
                }
                
                Spacer()
                
                Button {
                    HapticManager.shared.impact(.medium)
                    if let url = app.downloadURL {
                        DownloadManager.shared.startDownload(url: url, appName: app.name, iconURL: app.iconURL)
                        appState.showToast("Downloading \(app.name)...", type: .info)
                    }
                } label: {
                    Text(LocalizedStrings.actionGet)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(appState.currentAccentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(appState.currentAccentColor.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(app.developerName ?? "Developer")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("v\(app.version)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 18)
    }
}
