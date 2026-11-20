//
//  SourceParserService.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

public enum SourceParserError: LocalizedError {
    case invalidURL
    case networkError(String)
    case unsupportedFormat
    case emptyRepository
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided repository URL is invalid."
        case .networkError(let details):
            return "Network error while fetching repository: \(details)"
        case .unsupportedFormat:
            return "The source JSON format is not supported (Must be AltStore or Scarlet format)."
        case .emptyRepository:
            return "The repository does not contain any applications."
        }
    }
}

/// Dispatches repository fetching and automatically detects AltStore vs Scarlet schema
public final class SourceParserService {
    public static let shared = SourceParserService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }
    
    /// Fetches and parses a repository from a given URL
    public func fetchSource(from url: URL) async throws -> (SourceModel, [AppModel]) {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw SourceParserError.networkError("HTTP status \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        // Attempt AltStore format first
        if let result = try? AltStoreSourceParser.shared.parse(data: data, sourceURL: url) {
            return result
        }
        
        // Attempt Scarlet format
        if let result = try? ScarletSourceParser.shared.parse(data: data, sourceURL: url) {
            return result
        }
        
        throw SourceParserError.unsupportedFormat
    }
}
