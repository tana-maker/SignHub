//
//  FilesView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import UniformTypeIdentifiers

public struct FilesView: View {
    @StateObject private var viewModel = FilesViewModel()
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            List(selection: $viewModel.selectedFileIDs) {
                if viewModel.filteredFiles.isEmpty {
                    EmptyStateView(
                        iconName: "folder.badge.plus",
                        title: "No IPAs in Library",
                        subtitle: "Import IPAs from the Files app, download them from repositories, or import from URL.",
                        actionTitle: "Import from Files",
                        accentColor: appState.currentAccentColor
                    ) {
                        viewModel.isShowingFileImporter = true
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } else {
                    ForEach(viewModel.filteredFiles) { item in
                        FileRowView(
                            item: item,
                            isEditMode: viewModel.isEditMode,
                            isSelected: viewModel.selectedFileIDs.contains(item.id),
                            onInspect: {
                                viewModel.inspectingFile = item
                            },
                            onSign: {
                                appState.triggerSigning(for: item)
                            },
                            onRename: {
                                viewModel.renamingFile = item
                                viewModel.renameText = item.fileName
                            },
                            onDelete: {
                                try? viewModel.storage.deleteIPA(item: item)
                            }
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $viewModel.searchText, prompt: "Search imported IPAs...")
            .navigationTitle(LocalizedStrings.tabFiles)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.storage.files.isEmpty {
                        Button(viewModel.isEditMode ? "Done" : "Edit") {
                            withAnimation {
                                viewModel.isEditMode.toggle()
                                if !viewModel.isEditMode {
                                    viewModel.selectedFileIDs.removeAll()
                                }
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.isShowingFileImporter = true
                        } label: {
                            Label("Import from Files", systemImage: "doc.badge.plus")
                        }
                        
                        Button {
                            viewModel.isShowingURLImporter = true
                        } label: {
                            Label("Download from URL", systemImage: "link.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(appState.currentAccentColor)
                    }
                }
            }
            .fileImporter(
                isPresented: $viewModel.isShowingFileImporter,
                allowedContentTypes: [UTType(filenameExtension: "ipa") ?? .archive],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    for url in urls {
                        _ = try? viewModel.storage.importIPA(from: url)
                    }
                    appState.showToast("Imported \(urls.count) file(s)", type: .success)
                case .failure(let error):
                    appState.showToast(error.localizedDescription, type: .error)
                }
            }
            .alert("Rename IPA", isPresented: Binding(
                get: { viewModel.renamingFile != nil },
                set: { if !$0 { viewModel.renamingFile = nil } }
            )) {
                TextField("New Name", text: $viewModel.renameText)
                Button("Cancel", role: .cancel) { viewModel.renamingFile = nil }
                Button("Rename") { viewModel.confirmRename() }
            }
            .sheet(item: $viewModel.inspectingFile) { file in
                IPAInspectorView(fileItem: file)
            }
            .alert("Import from URL", isPresented: $viewModel.isShowingURLImporter) {
                TextField("https://example.com/app.ipa", text: $viewModel.urlImportString)
                Button("Cancel", role: .cancel) {}
                Button("Download") {
                    viewModel.importFromURL(urlString: viewModel.urlImportString)
                    viewModel.urlImportString = ""
                }
            }
            
            // Multi-Select Toolbar
            if viewModel.isEditMode && !viewModel.selectedFileIDs.isEmpty {
                MultiSelectToolbar(
                    selectedCount: viewModel.selectedFileIDs.count,
                    onDelete: {
                        viewModel.deleteSelected()
                    }
                )
                .padding(.bottom, 60) // Positioned above floating tab bar
            }
        }
        .onAppear {
            viewModel.storage.reloadFiles()
        }
    }
}
