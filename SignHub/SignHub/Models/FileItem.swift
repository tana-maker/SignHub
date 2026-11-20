//
//  FileItem.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// Represents an IPA file located in the user's local Documents library
public struct FileItem: Identifiable, Hashable {
    public let id: String
    public var fileURL: URL
    public var fileName: String
    public var fileSize: Int64
    public var creationDate: Date
    public var metadata: IPAMetadata?
    
    public init(
        id: String = UUID().uuidString,
        fileURL: URL,
        fileName: String,
        fileSize: Int64 = 0,
        creationDate: Date = Date(),
        metadata: IPAMetadata? = nil
    ) {
        self.id = id
        self.fileURL = fileURL
        self.fileName = fileName
        self.fileSize = fileSize
        self.creationDate = creationDate
        self.metadata = metadata
    }
}
