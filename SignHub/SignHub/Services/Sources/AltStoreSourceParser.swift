//
//  AltStoreSourceParser.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// Parser for standard AltStore repository format v1
public final class AltStoreSourceParser {
    public static let shared = AltStoreSourceParser()
    
    // AltStore DTOs
    struct AltStoreRepoDTO: Decodable {
        let name: String
        let identifier: String
        let iconURL: String?
        let apps: [AltStoreAppDTO]?
        let news: [AltStoreNewsDTO]?
    }
    
    struct AltStoreAppDTO: Decodable {
        let name: String
        let bundleIdentifier: String
        let developerName: String?
        let version: String
        let versionDate: String?
        let versionDescription: String?
        let downloadURL: String
        let localizedDescription: String?
        let iconURL: String?
        let size: Int64?
        let tintColor: String?
        let category: String?
        let screenshotURLs: [String]?
    }
    
    struct AltStoreNewsDTO: Decodable {
        let title: String
        let identifier: String
        let caption: String?
        let date: String?
    }
    
    private init() {}
    
    /// Parses an AltStore JSON payload into a SourceModel and array of AppModels
    /// - Parameters:
    ///   - data: Raw JSON data from repository endpoint
    ///   - sourceURL: URL of the source repository
    /// - Returns: Tuple of (SourceModel, [AppModel])
    public func parse(data: Data, sourceURL: URL) throws -> (SourceModel, [AppModel]) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let repo = try decoder.decode(AltStoreRepoDTO.self, from: data)
        let sourceID = repo.identifier.isEmpty ? UUID().uuidString : repo.identifier
        
        let sourceModel = SourceModel(
            id: sourceID,
            name: repo.name,
            identifier: repo.identifier,
            url: sourceURL,
            iconURL: repo.iconURL.flatMap(URL.init),
            appCount: repo.apps?.count ?? 0,
            lastUpdated: Date(),
            format: .altStore,
            isEnabled: true
        )
        
        let dateFormatter = ISO8601DateFormatter()
        
        let apps = (repo.apps ?? []).map { dto -> AppModel in
            let date = dto.versionDate.flatMap(dateFormatter.date) ?? Date()
            return AppModel(
                id: "\(sourceID)-\(dto.bundleIdentifier)",
                name: dto.name,
                bundleIdentifier: dto.bundleIdentifier,
                version: dto.version,
                developerName: dto.developerName,
                iconURL: dto.iconURL.flatMap(URL.init),
                downloadURL: URL(string: dto.downloadURL),
                localizedDescription: dto.localizedDescription,
                size: dto.size ?? 0,
                category: dto.category ?? "Utilities",
                sourceID: sourceID,
                releaseDate: date,
                screenshotURLs: (dto.screenshotURLs ?? []).compactMap { URL(string: $0) }
            )
        }
        
        return (sourceModel, apps)
    }
}
