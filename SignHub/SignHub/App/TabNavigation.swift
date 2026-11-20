//
//  TabNavigation.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

/// iPhone layout with floating glass pill tab bar
public struct TabNavigation: View {
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            Group {
                switch appState.selectedTab {
                case .apps:
                    NavigationStack {
                        AppsView()
                    }
                case .sources:
                    NavigationStack {
                        SourcesView()
                    }
                case .files:
                    NavigationStack {
                        FilesView()
                    }
                case .downloads:
                    NavigationStack {
                        DownloadsView()
                    }
                case .settings:
                    NavigationStack {
                        SettingsView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Floating Tab Bar
            FloatingTabBar(
                selectedTab: $appState.selectedTab,
                downloadsBadgeCount: appState.activeDownloadsCount,
                accentColor: appState.currentAccentColor
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
