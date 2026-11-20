//
//  SourcesView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct SourcesView: View {
    @StateObject private var viewModel = SourcesViewModel()
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        List {
            Section {
                ForEach(viewModel.sources) { source in
                    NavigationLink(destination: SourceDetailView(source: source)) {
                        HStack(spacing: 14) {
                            if let iconURL = source.iconURL {
                                AsyncImage(url: iconURL) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    Color.secondary.opacity(0.15)
                                }
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(appState.currentAccentColor.opacity(0.15))
                                    Image(systemName: "globe")
                                        .foregroundColor(appState.currentAccentColor)
                                        .font(.system(size: 20))
                                }
                                .frame(width: 44, height: 44)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(source.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 6) {
                                    Text("\(source.appCount) Apps")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    
                                    Text(source.format.rawValue)
                                        .font(.system(size: 11, weight: .medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.primary.opacity(0.08)))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            if let idx = viewModel.sources.firstIndex(where: { $0.id == source.id }) {
                                viewModel.deleteSource(at: IndexSet(integer: idx))
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onMove(perform: viewModel.moveSources)
            } header: {
                Text("Installed Repositories")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(LocalizedStrings.tabSources)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        viewModel.isAddingSource = true
                    } label: {
                        Label("Add by URL", systemImage: "link")
                    }
                    
                    Button {
                        viewModel.isShowingQRScanner = true
                    } label: {
                        Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(appState.currentAccentColor)
                }
            }
        }
        .refreshable {
            await viewModel.refreshAllSources()
        }
        .sheet(isPresented: $viewModel.isAddingSource) {
            AddSourceSheet { url in
                Task {
                    _ = await viewModel.addSource(url: url)
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingQRScanner) {
            QRScannerView { scannedURLString in
                if let url = URL(string: scannedURLString) {
                    Task {
                        _ = await viewModel.addSource(url: url)
                    }
                }
            }
        }
    }
}
