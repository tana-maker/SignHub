//
//  EmptyStateView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

/// Accessible empty state with modern iconography, descriptive copy, and optional action trigger
public struct EmptyStateView: View {
    public var iconName: String
    public var title: String
    public var subtitle: String
    public var actionTitle: String?
    public var accentColor: Color = .blue
    public var action: (() -> Void)?
    
    public init(
        iconName: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        accentColor: Color = .blue,
        action: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.accentColor = accentColor
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 80, height: 80)
                
                Image(systemName: iconName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            .padding(.bottom, 4)
            
            Text(title)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.shared.impact(.light)
                    action()
                }) {
                    Text(actionTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(accentColor)
                                .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(.top, 8)
                .minTapTarget()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
