//
//  DownloadItem.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

public enum DownloadStatus: String, Codable {
    case queued = "Queued"
    case downloading = "Downloading"
    case paused = "Paused"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
}

/// Represents an item in the download queue
public struct DownloadItem: Identifiable, Codable, Hashable {
    public let id: String
    public var url: URL
    public var destinationURL: URL
    public var appName: String
    public var iconURL: URL?
    public var totalBytes: Int64
    public var receivedBytes: Int64
    public var progress: Double
    public var speedBytesPerSec: Int64
    public var status: DownloadStatus
    public var errorMessage: String?
    public var taskIdentifier: Int?
    public var resumeData: Data?
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        url: URL,
        destinationURL: URL,
        appName: String,
        iconURL: URL? = nil,
        totalBytes: Int64 = 0,
        receivedBytes: Int64 = 0,
        progress: Double = 0.0,
        speedBytesPerSec: Int64 = 0,
        status: DownloadStatus = .queued,
        errorMessage: String? = nil,
        taskIdentifier: Int? = nil,
        resumeData: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.destinationURL = destinationURL
        self.appName = appName
        self.iconURL = iconURL
        self.totalBytes = totalBytes
        self.receivedBytes = receivedBytes
        self.progress = progress
        self.speedBytesPerSec = speedBytesPerSec
        self.status = status
        self.errorMessage = errorMessage
        self.taskIdentifier = taskIdentifier
        self.resumeData = resumeData
        self.createdAt = createdAt
    }
}
