//
//  Formatting+Extensions.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

extension Int64 {
    /// Formats byte count into human-readable string (e.g. "45.2 MB", "1.24 GB")
    public var formattedByteCount: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self)
    }
    
    /// Formats transfer rate (e.g. "4.2 MB/s")
    public var formattedSpeedString: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: self))/s"
    }
}

extension Double {
    /// Formats percentage string (e.g. "45%")
    public var formattedPercentage: String {
        let percent = Int(self * 100)
        return "\(percent)%"
    }
}
