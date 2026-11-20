//
//  AppsView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct AppsView: View {
    @StateObject private var viewModel = AppsViewModel()
    @EnvironmentObject private var appState: AppState
    
    let gridColumns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
    ]
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Category Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            let isSelected = viewModel.selectedCategory == category
                            Button {
                                HapticManager.shared.impact(.light)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.selectedCategory = category
                                }
                            } label: {
                                Text(category)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? appState.currentAccentColor : Color.primary.opacity(0.06))
                                    )
                                    .foregroundColor(isSelected ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 4)
                
                // Apps Grid or List
                if viewModel.isLoading {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonLoader(style: .appRow)
                        }
                    }
                    .padding(.horizontal, 20)
                } else if viewModel.filteredApps.isEmpty {
                    EmptyStateView(
                        iconName: "magnifyingglass",
                        title: "No Apps Found",
                        subtitle: "Try adjusting your search filters or add more sources in the Sources tab.",
                        accentColor: appState.currentAccentColor
                    )
                    .padding(.top, 40)
                } else if viewModel.isGridView {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(viewModel.filteredApps) { app in
                            NavigationLink(destination: AppDetailView(app: app)) {
                                AppCardGridItem(app: app)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.filteredApps) { app in
                            NavigationLink(destination: AppDetailView(app: app)) {
                                AppCardRowItem(app: app)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 90) // Ensure spacing above floating tab bar
        }
        .searchable(text: $viewModel.searchText, prompt: "Search apps, bundle IDs, tools...")
        .navigationTitle(LocalizedStrings.tabApps)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation {
                        viewModel.isGridView.toggle()
                    }
                } label: {
                    Image(systemName: viewModel.isGridView ? "list.bullet" : "square.grid.2x2")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}
