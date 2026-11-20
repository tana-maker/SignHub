//
//  OnboardingView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var currentPage: Int = 0
    
    let pages: [(icon: String, title: String, desc: String)] = [
        ("globe.badge.chevron.backward", "Discover & Add Sources", "Browse hundreds of open-source apps or connect AltStore and Scarlet repositories with a single tap or QR code scan."),
        ("checkmark.seal.fill", "Import Your Certificate", "Easily import your personal Apple Developer .p12 and .mobileprovision file. Passwords remain encrypted in your device Keychain."),
        ("signature", "Customize & Sign", "Rename apps, modify bundle identifiers, inject custom dylibs and tweaks, and remove device restrictions prior to codesigning."),
        ("arrow.down.app.fill", "One-Tap Wireless Install", "SignHub starts a secure local HTTPS server to trigger genuine iOS OTA installation without computers or cables.")
    ]
    
    public var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button("Skip") {
                    dismiss()
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.trailing, 20)
                .padding(.top, 16)
            }
            
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { idx in
                    VStack(spacing: 24) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(appState.currentAccentColor.opacity(0.12))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: pages[idx].icon)
                                .font(.system(size: 54))
                                .foregroundColor(appState.currentAccentColor)
                        }
                        
                        VStack(spacing: 12) {
                            Text(pages[idx].title)
                                .font(.system(size: 24, weight: .bold))
                                .multilineTextAlignment(.center)
                            
                            Text(pages[idx].desc)
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 36)
                                .lineSpacing(4)
                        }
                        
                        Spacer()
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    dismiss()
                }
            } label: {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(appState.currentAccentColor))
                    .padding(.horizontal, 28)
            }
            .minTapTarget()
            .padding(.bottom, 24)
        }
    }
}
