//
//  DownloadsView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct DownloadsView: View {
    @StateObject private var viewModel = DownloadsViewModel()
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        List {
            if !viewModel.activeDownloads.isEmpty {
                Section {
                    ForEach(viewModel.activeDownloads) { item in
                        DownloadRowView(item: item, viewModel: viewModel)
                    }
                } header: {
                    Text("In Progress")
                }
            }
            
            if !viewModel.completedDownloads.isEmpty {
                Section {
                    ForEach(viewModel.completedDownloads) { item in
                        DownloadRowView(item: item, viewModel: viewModel)
                    }
                } header: {
                    HStack {
                        Text("Finished")
                        Spacer()
                        Button("Clear") {
                            viewModel.clearCompleted()
                        }
                        .font(.system(size: 13, weight: .medium))
                    }
                }
            }
            
            if viewModel.downloadManager.downloads.isEmpty {
                EmptyStateView(
                    iconName: "arrow.down.circle",
                    title: "No Active Downloads",
                    subtitle: "When you download IPAs from sources or web links, their progress will appear here.",
                    actionTitle: "Add Download URL",
                    accentColor: appState.currentAccentColor
                ) {
                    viewModel.isShowingAddDownloadSheet = true
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(LocalizedStrings.tabDownloads)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.isShowingAddDownloadSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddDownloadSheet) {
            AddDownloadSheet { url, name in
                viewModel.startNewDownload(url: url, appName: name)
            }
        }
    }
}
