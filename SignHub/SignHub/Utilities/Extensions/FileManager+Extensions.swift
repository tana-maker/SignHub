//
//  FileManager+Extensions.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

extension FileManager {
    /// App documents directory
    public var documentsDirectory: URL {
        return urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// App caches directory
    public var cachesDirectory: URL {
        return urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    /// Dedicated directory for storing imported/saved IPAs
    public var ipasDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("IPAs", isDirectory: true)
        if !fileExists(atPath: dir.path) {
            try? createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    /// Dedicated directory for storing signed IPAs ready for installation
    public var signedIPAsDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("Signed", isDirectory: true)
        if !fileExists(atPath: dir.path) {
            try? createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    /// Dedicated directory for storing imported certificates (.p12 and .mobileprovision)
    public var certificatesDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("Certificates", isDirectory: true)
        if !fileExists(atPath: dir.path) {
            try? createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    /// Temporary directory for unpacking and signing IPAs
    public var signingWorkDirectory: URL {
        let dir = temporaryDirectory.appendingPathComponent("SignHubWork", isDirectory: true)
        if !fileExists(atPath: dir.path) {
            try? createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    /// Calculates the total size in bytes of a file or directory
    public func allocatedSizeOfDirectory(at url: URL) -> Int64 {
        guard let enumerator = enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                  let isDir = resourceValues.isDirectory, !isDir,
                  let size = resourceValues.fileSize else {
                continue
            }
            total += Int64(size)
        }
        return total
    }
    
    /// Safely clears all contents inside a given directory without removing the directory itself
    public func clearContents(of directoryURL: URL) {
        guard let items = try? contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else { return }
        for item in items {
            try? removeItem(at: item)
        }
    }
}
