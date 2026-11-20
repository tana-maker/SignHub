//
//  AppLogger.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation
import Combine

/// Centralized diagnostic logger collecting in-memory logs and supporting export to text/zip
public final class AppLogger: ObservableObject {
    public static let shared = AppLogger()
    
    @Published public private(set) var logs: [SigningLogEntry] = []
    
    private let queue = DispatchQueue(label: "com.signhub.logger")
    
    private init() {
        log("SignHub initialized.", level: .info)
    }
    
    public func log(_ message: String, level: LogLevel = .info) {
        queue.async {
            let entry = SigningLogEntry(level: level, message: message)
            DispatchQueue.main.async {
                self.logs.append(entry)
                // Cap to 1000 entries
                if self.logs.count > 1000 {
                    self.logs.removeFirst(100)
                }
            }
        }
    }
    
    /// Generates a plain text file containing all logged events
    public func exportLogsAsFile() -> URL? {
        let logText = logs.map { "[\($0.formattedTimestamp)] [\($0.level.rawValue)] \($0.message)" }.joined(separator: "\n")
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("SignHub_Diagnostic_Logs.txt")
        do {
            try logText.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
    
    public func clearLogs() {
        logs.removeAll()
    }
}
