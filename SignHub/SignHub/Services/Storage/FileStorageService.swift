//
//  FileStorageService.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation
import Combine

/// Manages physical IPA files inside the local documents storage
@MainActor
public final class FileStorageService: ObservableObject {
    public static let shared = FileStorageService()
    
    @Published public private(set) var files: [FileItem] = []
    
    private init() {
        reloadFiles()
    }
    
    /// Scans the IPAs directory and reloads all .ipa files
    public func reloadFiles() {
        let dir = FileManager.default.ipasDirectory
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            self.files = []
            return
        }
        
        let ipaURLs = fileURLs.filter { $0.pathExtension.lowercased() == "ipa" }
        
        self.files = ipaURLs.map { url -> FileItem in
            let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            let size = Int64(resourceValues?.fileSize ?? 0)
            let date = resourceValues?.contentModificationDate ?? Date()
            
            return FileItem(
                id: url.lastPathComponent,
                fileURL: url,
                fileName: url.deletingPathExtension().lastPathComponent,
                fileSize: size,
                creationDate: date
            )
        }.sorted(by: { $0.creationDate > $1.creationDate })
    }
    
    /// Imports an IPA from an external URL (Files picker or AirDrop)
    public func importIPA(from externalURL: URL) throws -> FileItem {
        let isAccessing = externalURL.startAccessingSecurityScopedResource()
        defer {
            if isAccessing { externalURL.stopAccessingSecurityScopedResource() }
        }
        
        let destination = FileManager.default.ipasDirectory.appendingPathComponent(externalURL.lastPathComponent)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: externalURL, to: destination)
        reloadFiles()
        
        guard let item = files.first(where: { $0.fileURL.lastPathComponent == destination.lastPathComponent }) else {
            throw NSError(domain: "SignHub", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to locate imported file."])
        }
        return item
    }
    
    /// Renames an existing IPA file
    public func renameIPA(item: FileItem, newName: String) throws {
        let sanitized = newName.replacingOccurrences(of: "/", with: "-").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { return }
        
        let newURL = FileManager.default.ipasDirectory.appendingPathComponent("\(sanitized).ipa")
        try FileManager.default.moveItem(at: item.fileURL, to: newURL)
        reloadFiles()
    }
    
    /// Deletes a single IPA
    public func deleteIPA(item: FileItem) throws {
        try FileManager.default.removeItem(at: item.fileURL)
        reloadFiles()
    }
    
    /// Batch deletes multiple IPAs
    public func deleteIPAs(items: [FileItem]) {
        for item in items {
            try? FileManager.default.removeItem(at: item.fileURL)
        }
        reloadFiles()
    }
}
