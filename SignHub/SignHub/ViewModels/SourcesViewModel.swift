//
//  SourcesViewModel.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import Combine

@MainActor
public final class SourcesViewModel: ObservableObject {
    @Published public var sources: [SourceModel] = []
    @Published public var isLoading: Bool = false
    @Published public var isAddingSource: Bool = false
    @Published public var isShowingQRScanner: Bool = false
    @Published public var errorMessage: String?
    
    private let storageKey = "SignHub_User_Sources"
    
    public init() {
        loadSources()
        if sources.isEmpty {
            loadDefaultSources()
        }
    }
    
    /// Loads stored sources from UserDefaults
    public func loadSources() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let list = try? JSONDecoder().decode([SourceModel].self, from: data) {
            self.sources = list.sorted(by: { $0.orderIndex < $1.orderIndex })
        }
    }
    
    /// Saves sources to UserDefaults
    public func saveSources() {
        if let data = try? JSONEncoder().encode(sources) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    /// Adds default community sources on first launch
    private func loadDefaultSources() {
        var defaults: [SourceModel] = []
        if let altURL = URL(string: "https://apps.altstore.io") {
            defaults.append(SourceModel(
                name: "AltStore Community",
                identifier: "com.altstore.community",
                url: altURL,
                appCount: 12,
                format: .altStore,
                orderIndex: 0
            ))
        }
        if let scarletURL = URL(string: "https://repo.usescarlet.com") {
            defaults.append(SourceModel(
                name: "Scarlet Official Repo",
                identifier: "com.scarlet.official",
                url: scarletURL,
                appCount: 28,
                format: .scarlet,
                orderIndex: 1
            ))
        }
        self.sources = defaults
        saveSources()
    }
    
    /// Adds a new repository source by URL
    /// - Parameter url: Repository JSON URL
    /// - Returns: True if fetched and added successfully
    public func addSource(url: URL) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let (source, apps) = try await SourceParserService.shared.fetchSource(from: url)
            var newSource = source
            newSource.orderIndex = sources.count
            newSource.appCount = apps.count
            
            // Check if already exists
            if let existingIndex = sources.firstIndex(where: { $0.url == url || $0.identifier == newSource.identifier }) {
                sources[existingIndex] = newSource
            } else {
                sources.append(newSource)
            }
            
            saveSources()
            isLoading = false
            HapticManager.shared.notification(.success)
            AppState.shared.showToast("Source added: \(newSource.name)", type: .success)
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            HapticManager.shared.notification(.error)
            AppState.shared.showToast(error.localizedDescription, type: .error)
            return false
        }
    }
    
    /// Refreshes all enabled sources
    public func refreshAllSources() async {
        isLoading = true
        for i in 0..<sources.count {
            guard sources[i].isEnabled else { continue }
            if let (_, apps) = try? await SourceParserService.shared.fetchSource(from: sources[i].url) {
                sources[i].appCount = apps.count
                sources[i].lastUpdated = Date()
            }
        }
        saveSources()
        isLoading = false
        HapticManager.shared.notification(.success)
    }
    
    /// Deletes a source
    public func deleteSource(at offsets: IndexSet) {
        sources.remove(atOffsets: offsets)
        saveSources()
    }
    
    /// Moves sources for reordering
    public func moveSources(from source: IndexSet, to destination: Int) {
        sources.move(fromOffsets: source, toOffset: destination)
        for i in 0..<sources.count {
            sources[i].orderIndex = i
        }
        saveSources()
    }
}
