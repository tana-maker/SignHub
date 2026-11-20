//
//  SkeletonLoader.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

/// Reusable placeholder skeleton for apps, sources, and download items
public struct SkeletonLoader: View {
    public enum Style {
        case appRow
        case appCard
        case sourceRow
    }
    
    public var style: Style
    
    public init(style: Style = .appRow) {
        self.style = style
    }
    
    public var body: some View {
        Group {
            switch style {
            case .appRow:
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 58, height: 58)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: 140, height: 16)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.08))
                            .frame(width: 90, height: 12)
                    }
                    
                    Spacer()
                    
                    Capsule()
                        .fill(Color.primary.opacity(0.10))
                        .frame(width: 68, height: 32)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassCard(cornerRadius: 16)
                
            case .appCard:
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 72, height: 72)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.12))
                        .frame(width: 110, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 70, height: 10)
                }
                .padding(16)
                .glassCard(cornerRadius: 20)
                
            case .sourceRow:
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: 130, height: 15)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.08))
                            .frame(width: 180, height: 11)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .glassCard(cornerRadius: 18)
            }
        }
        .shimmer()
    }
}
