//
//  SidebarNavigation.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

/// iPad layout with adaptive NavigationSplitView sidebar
public struct SidebarNavigation: View {
    @EnvironmentObject private var appState: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(AppTab.allCases, selection: Binding(
                get: { appState.selectedTab },
                set: { if let tab = $0 { appState.selectedTab = tab } }
            )) { tab in
                NavigationLink(value: tab) {
                    Label {
                        Text(tab.title)
                            .font(.system(size: 16, weight: .medium))
                    } icon: {
                        Image(systemName: tab.systemImage)
                            .foregroundColor(appState.selectedTab == tab ? appState.currentAccentColor : .secondary)
                    }
                    .badge(tab == .downloads && appState.activeDownloadsCount > 0 ? "\(appState.activeDownloadsCount)" : nil)
                }
            }
            .navigationTitle("SignHub")
            .listStyle(.sidebar)
        } detail: {
            NavigationStack {
                switch appState.selectedTab {
                case .apps:
                    AppsView()
                case .sources:
                    SourcesView()
                case .files:
                    FilesView()
                case .downloads:
                    DownloadsView()
                case .settings:
                    SettingsView()
                }
            }
        }
    }
}
