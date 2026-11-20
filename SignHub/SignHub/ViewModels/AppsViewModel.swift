//
//  AppsViewModel.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import Combine

public enum AppSourceFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case sources = "Repositories"
    case imported = "Imported IPAs"
    
    public var id: String { rawValue }
}

@MainActor
public final class AppsViewModel: ObservableObject {
    @Published public var apps: [AppModel] = []
    @Published public var searchText: String = ""
    @Published public var selectedFilter: AppSourceFilter = .all
    @Published public var selectedCategory: String = "All"
    @Published public var isGridView: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var inspectingApp: AppModel?
    
    public var categories: [String] {
        var set = Set(apps.compactMap { $0.category })
        var arr = Array(set).sorted()
        arr.insert("All", at: 0)
        return arr
    }
    
    public var filteredApps: [AppModel] {
        apps.filter { app in
            let matchesSearch = searchText.isEmpty ||
                app.name.localizedCaseInsensitiveContains(searchText) ||
                app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == "All" || app.category == selectedCategory
            
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .sources:
                matchesFilter = app.sourceID != nil
            case .imported:
                matchesFilter = app.sourceID == nil
            }
            
            return matchesSearch && matchesCategory && matchesFilter
        }
    }
    
    public init() {
        loadMockInitialApps()
    }
    
    public func loadMockInitialApps() {
        // Load initial featured community apps
        self.apps = [
            AppModel(
                name: "Delta Emulator",
                bundleIdentifier: "com.rileytestut.Delta",
                version: "1.6.1",
                developerName: "Riley Testut",
                iconURL: URL(string: "https://deltaemulator.com/assets/img/icon.png"),
                downloadURL: URL(string: "https://github.com/rileytestut/Delta/releases/download/v1.6.1/Delta.ipa"),
                localizedDescription: "Delta is an all-in-one classic video game emulator for iOS, supporting Nintendo games.",
                size: 65_400_000,
                category: "Games",
                sourceID: "com.altstore.community"
            ),
            AppModel(
                name: "Clip",
                bundleIdentifier: "com.rileytestut.Clip",
                version: "1.1.2",
                developerName: "Riley Testut",
                iconURL: nil,
                downloadURL: URL(string: "https://github.com/rileytestut/Clip/releases/download/v1.1.2/Clip.ipa"),
                localizedDescription: "Clip is a powerful clipboard manager that runs quietly in the background on iOS.",
                size: 14_200_000,
                category: "Utilities",
                sourceID: "com.altstore.community"
            ),
            AppModel(
                name: "Kodi",
                bundleIdentifier: "org.xbmc.kodi-ios",
                version: "21.0",
                developerName: "Kodi Foundation",
                iconURL: nil,
                downloadURL: URL(string: "https://mirrors.kodi.tv/releases/darwin/ios/kodi-21.0-Omega-ios.ipa"),
                localizedDescription: "Kodi is an open-source media player software application developed by the XBMC Foundation.",
                size: 120_500_000,
                category: "Entertainment",
                sourceID: "com.scarlet.official"
            ),
            AppModel(
                name: "UTM Virtual Machines",
                bundleIdentifier: "com.utmapp.UTM",
                version: "4.5.3",
                developerName: "UTM Team",
                iconURL: nil,
                downloadURL: URL(string: "https://github.com/utmapp/UTM/releases/download/v4.5.3/UTM.ipa"),
                localizedDescription: "Run Windows, Linux, and classic OS operating systems directly on your iPhone and iPad.",
                size: 89_300_000,
                category: "Developer Tools",
                sourceID: "com.altstore.community"
            )
        ]
    }
}
