//
//  SigningLogEntry.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

public enum LogLevel: String, Codable {
    case info = "INFO"
    case debug = "DEBUG"
    case warning = "WARN"
    case error = "ERROR"
    case success = "SUCCESS"
}

/// Represents an individual output log entry during IPA parsing and signing
public struct SigningLogEntry: Identifiable, Codable, Hashable {
    public let id: String
    public let timestamp: Date
    public let level: LogLevel
    public let message: String
    
    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        level: LogLevel = .info,
        message: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
    }
}
