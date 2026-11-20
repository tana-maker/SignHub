//
//  AppModel.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// Represents an application available from a repository source or imported IPA
public struct AppModel: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var bundleIdentifier: String
    public var version: String
    public var buildNumber: String?
    public var developerName: String?
    public var iconURL: URL?
    public var downloadURL: URL?
    public var localizedDescription: String?
    public var size: Int64
    public var category: String?
    public var sourceID: String?
    public var minimumOSVersion: String?
    public var releaseDate: Date?
    public var screenshotURLs: [URL]?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        bundleIdentifier: String,
        version: String,
        buildNumber: String? = nil,
        developerName: String? = nil,
        iconURL: URL? = nil,
        downloadURL: URL? = nil,
        localizedDescription: String? = nil,
        size: Int64 = 0,
        category: String? = "Utilities",
        sourceID: String? = nil,
        minimumOSVersion: String? = "15.0",
        releaseDate: Date? = Date(),
        screenshotURLs: [URL]? = []
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.buildNumber = buildNumber
        self.developerName = developerName
        self.iconURL = iconURL
        self.downloadURL = downloadURL
        self.localizedDescription = localizedDescription
        self.size = size
        self.category = category
        self.sourceID = sourceID
        self.minimumOSVersion = minimumOSVersion
        self.releaseDate = releaseDate
        self.screenshotURLs = screenshotURLs
    }
}
