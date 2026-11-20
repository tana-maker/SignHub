//
//  SourceModel.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// Defines supported repository source JSON schemas
public enum SourceFormat: String, Codable, CaseIterable {
    case altStore = "AltStore"
    case scarlet = "Scarlet"
    case custom = "Custom"
}

/// Represents a software repository source
public struct SourceModel: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var identifier: String
    public var url: URL
    public var iconURL: URL?
    public var appCount: Int
    public var lastUpdated: Date
    public var format: SourceFormat
    public var isEnabled: Bool
    public var orderIndex: Int
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        identifier: String,
        url: URL,
        iconURL: URL? = nil,
        appCount: Int = 0,
        lastUpdated: Date = Date(),
        format: SourceFormat = .altStore,
        isEnabled: Bool = true,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.identifier = identifier
        self.url = url
        self.iconURL = iconURL
        self.appCount = appCount
        self.lastUpdated = lastUpdated
        self.format = format
        self.isEnabled = isEnabled
        self.orderIndex = orderIndex
    }
}
