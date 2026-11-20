//
//  FloatingTabBar.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public enum AppTab: Int, CaseIterable, Identifiable {
    case apps = 0
    case sources = 1
    case files = 2
    case downloads = 3
    case settings = 4
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .apps: return LocalizedStrings.tabApps
        case .sources: return LocalizedStrings.tabSources
        case .files: return LocalizedStrings.tabFiles
        case .downloads: return LocalizedStrings.tabDownloads
        case .settings: return LocalizedStrings.tabSettings
        }
    }
    
    public var systemImage: String {
        switch self {
        case .apps: return "square.grid.2x2.fill"
        case .sources: return "globe.badge.chevron.backward"
        case .files: return "folder.fill"
        case .downloads: return "arrow.down.circle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

/// Modern floating pill tab bar with glassmorphic blur, active spring highlight, and haptics
public struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab
    var downloadsBadgeCount: Int = 0
    var accentColor: Color = .blue
    
    public var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = selectedTab == tab
                
                Button {
                    if selectedTab != tab {
                        HapticManager.shared.impact(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? accentColor : .secondary)
                                .frame(height: 24)
                            
                            if tab == .downloads && downloadsBadgeCount > 0 {
                                Text("\(downloadsBadgeCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Color.red))
                                    .offset(x: 10, y: -6)
                            }
                        }
                        
                        Text(tab.title)
                            .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? accentColor : .secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isSelected ? accentColor.opacity(0.12) : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 8)
        )
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }
}
