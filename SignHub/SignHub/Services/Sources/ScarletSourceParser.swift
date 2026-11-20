//
//  ScarletSourceParser.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// Parser for Scarlet repository format (ITEMS and META dictionaries)
public final class ScarletSourceParser {
    public static let shared = ScarletSourceParser()
    
    struct ScarletRepoDTO: Decodable {
        let META: ScarletMetaDTO?
        let ITEMS: [ScarletItemDTO]?
    }
    
    struct ScarletMetaDTO: Decodable {
        let repoName: String?
        let repoIcon: String?
        let description: String?
    }
    
    struct ScarletItemDTO: Decodable {
        let name: String
        let bundleID: String?
        let version: String?
        let down: String? // Download URL in Scarlet repos
        let icon: String?
        let dev: String?
        let desc: String?
        let category: String?
    }
    
    private init() {}
    
    /// Parses a Scarlet JSON payload into a SourceModel and array of AppModels
    /// - Parameters:
    ///   - data: Raw JSON data from repository endpoint
    ///   - sourceURL: URL of the repository
    /// - Returns: Tuple of (SourceModel, [AppModel])
    public func parse(data: Data, sourceURL: URL) throws -> (SourceModel, [AppModel]) {
        let decoder = JSONDecoder()
        let repo = try decoder.decode(ScarletRepoDTO.self, from: data)
        
        let repoName = repo.META?.repoName ?? sourceURL.host ?? "Scarlet Repo"
        let sourceID = UUID().uuidString
        let iconURL = repo.META?.repoIcon.flatMap(URL.init)
        
        let apps = (repo.ITEMS ?? []).compactMap { item -> AppModel? in
            guard let downloadStr = item.down, let downloadURL = URL(string: downloadStr) else {
                return nil
            }
            let bundleID = item.bundleID ?? "com.scarlet.\(UUID().uuidString.prefix(8))"
            return AppModel(
                id: "\(sourceID)-\(bundleID)",
                name: item.name,
                bundleIdentifier: bundleID,
                version: item.version ?? "1.0",
                developerName: item.dev,
                iconURL: item.icon.flatMap(URL.init),
                downloadURL: downloadURL,
                localizedDescription: item.desc,
                size: 0,
                category: item.category ?? "Utilities",
                sourceID: sourceID,
                releaseDate: Date()
            )
        }
        
        let source = SourceModel(
            id: sourceID,
            name: repoName,
            identifier: "scarlet.\(sourceURL.host ?? "repo")",
            url: sourceURL,
            iconURL: iconURL,
            appCount: apps.count,
            lastUpdated: Date(),
            format: .scarlet,
            isEnabled: true
        )
        
        return (source, apps)
    }
}
