//
//  SignedAppCardView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct SignedAppCardView: View {
    public let app: InstalledAppModel
    public var onReSign: () -> Void
    public var onInstall: () -> Void
    
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        HStack(spacing: 14) {
            // Icon
            if let iconData = app.iconData, let uiImg = UIImage(data: iconData) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(appState.currentAccentColor.opacity(0.12))
                    Image(systemName: "app.fill")
                        .font(.system(size: 24))
                        .foregroundColor(appState.currentAccentColor)
                }
                .frame(width: 48, height: 48)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                
                Text(app.bundleIdentifier)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(app.expiryDate.expiryCountdownString)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(app.isExpired ? .red : (app.isExpiringSoon ? .orange : .green))
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(app.certificateName)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Re-Sign and Install Actions
            HStack(spacing: 8) {
                Button {
                    HapticManager.shared.impact(.light)
                    onReSign()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(appState.currentAccentColor)
                        .padding(8)
                        .background(Circle().fill(appState.currentAccentColor.opacity(0.12)))
                }
                .buttonStyle(.plain)
                
                Button {
                    HapticManager.shared.impact(.medium)
                    onInstall()
                } label: {
                    Text("Install")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(appState.currentAccentColor))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
