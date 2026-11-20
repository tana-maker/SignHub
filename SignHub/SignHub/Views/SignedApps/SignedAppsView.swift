//
//  SignedAppsView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct SignedAppsView: View {
    @ObservedObject private var viewModel = SignedAppsViewModel.shared
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        List {
            if viewModel.installedApps.isEmpty {
                EmptyStateView(
                    iconName: "checkmark.seal",
                    title: "No Signed Apps Yet",
                    subtitle: "Apps you sign and install will be monitored here with automatic certificate expiry countdowns.",
                    actionTitle: "Browse IPAs",
                    accentColor: appState.currentAccentColor
                ) {
                    appState.selectedTab = .files
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else {
                Section {
                    ForEach(viewModel.filteredApps) { app in
                        SignedAppCardView(app: app) {
                            viewModel.reSignApp(app)
                        } onInstall: {
                            let url = FileManager.default.signedIPAsDirectory.appendingPathComponent(app.signedIPAFileName)
                            appState.pendingInstallPackageURL = url
                            appState.pendingInstallAppName = app.name
                            appState.isPresentingInstallProgress = true
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let app = viewModel.filteredApps[index]
                            viewModel.removeApp(id: app.id)
                        }
                    }
                } header: {
                    Text("Installed Applications (\(viewModel.installedApps.count))")
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText, prompt: "Search signed apps...")
        .navigationTitle(LocalizedStrings.tabSigned)
    }
}
