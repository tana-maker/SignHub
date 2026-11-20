//
//  FilesViewModel.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import Combine

@MainActor
public final class FilesViewModel: ObservableObject {
    @Published public var storage = FileStorageService.shared
    @Published public var searchText: String = ""
    @Published public var isEditMode: Bool = false
    @Published public var selectedFileIDs: Set<String> = []
    @Published public var inspectingFile: FileItem?
    @Published public var renamingFile: FileItem?
    @Published public var renameText: String = ""
    @Published public var isShowingFileImporter: Bool = false
    @Published public var isShowingURLImporter: Bool = false
    @Published public var urlImportString: String = ""
    
    public init() {}
    
    public var filteredFiles: [FileItem] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return storage.files
        }
        return storage.files.filter {
            $0.fileName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    public func importFromURL(urlString: String) {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            AppState.shared.showToast("Invalid URL provided", type: .error)
            return
        }
        let appName = url.deletingPathExtension().lastPathComponent
        DownloadManager.shared.startDownload(url: url, appName: appName)
        AppState.shared.showToast("Queued download: \(appName)", type: .info)
    }
    
    public func deleteSelected() {
        let itemsToDelete = storage.files.filter { selectedFileIDs.contains($0.id) }
        storage.deleteIPAs(items: itemsToDelete)
        selectedFileIDs.removeAll()
        isEditMode = false
        HapticManager.shared.notification(.success)
    }
    
    public func confirmRename() {
        guard let item = renamingFile else { return }
        do {
            try storage.renameIPA(item: item, newName: renameText)
            HapticManager.shared.notification(.success)
            AppState.shared.showToast("Renamed successfully", type: .success)
        } catch {
            AppState.shared.showToast(error.localizedDescription, type: .error)
        }
        renamingFile = nil
    }
}
