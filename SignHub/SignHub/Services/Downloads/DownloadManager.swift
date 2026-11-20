//
//  DownloadManager.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation
import Combine
import SwiftUI

/// Centralized manager for queuing, executing, resuming, and tracking background IPA downloads
@MainActor
public final class DownloadManager: ObservableObject, DownloadManagerDelegate {
    public static let shared = DownloadManager()
    
    @Published public private(set) var downloads: [DownloadItem] = []
    
    private var session: URLSession
    private let delegate = BackgroundDownloadDelegate()
    private var tasks: [Int: URLSessionDownloadTask] = [:]
    private var taskIDToItemID: [Int: String] = [:]
    
    private let storageKey = "SignHub_Stored_Downloads"
    
    private init() {
        let config = URLSessionConfiguration.background(withIdentifier: "com.signhub.downloadsession")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        config.shouldUseExtendedBackgroundIdleMode = true
        
        let newSession = URLSession(configuration: config, delegate: self.delegate, delegateQueue: OperationQueue.main)
        self.session = newSession
        self.delegate.delegate = self
        
        loadSavedDownloads()
    }
    
    // MARK: - Public Actions
    
    /// Enqueues a new IPA download from a URL
    /// - Parameters:
    ///   - url: Remote URL pointing to the IPA file
    ///   - appName: Human-readable name of the application
    ///   - iconURL: Optional image URL for displaying the app icon
    /// - Returns: Newly queued DownloadItem
    @discardableResult
    public func startDownload(
        url: URL,
        appName: String,
        iconURL: URL? = nil
    ) -> DownloadItem {
        let itemID = UUID().uuidString
        let safeName = appName.replacingOccurrences(of: "/", with: "-")
        let destinationURL = FileManager.default.ipasDirectory.appendingPathComponent("\(safeName).ipa")
        
        let newItem = DownloadItem(
            id: itemID,
            url: url,
            destinationURL: destinationURL,
            appName: appName,
            iconURL: iconURL,
            status: .downloading
        )
        
        downloads.insert(newItem, at: 0)
        
        let task = session.downloadTask(with: url)
        tasks[task.taskIdentifier] = task
        taskIDToItemID[task.taskIdentifier] = itemID
        
        if let idx = downloads.firstIndex(where: { $0.id == itemID }) {
            downloads[idx].taskIdentifier = task.taskIdentifier
        }
        
        task.resume()
        saveDownloads()
        updateBadgeCount()
        
        return newItem
    }
    
    /// Pauses an active download and saves resume data
    /// - Parameter id: Unique identifier of the DownloadItem
    public func pauseDownload(id: String) {
        guard let idx = downloads.firstIndex(where: { $0.id == id }),
              let taskID = downloads[idx].taskIdentifier,
              let task = tasks[taskID] else { return }
        
        task.cancel { [weak self] resumeData in
            DispatchQueue.main.async {
                guard let self = self, let idx = self.downloads.firstIndex(where: { $0.id == id }) else { return }
                self.downloads[idx].status = .paused
                self.downloads[idx].resumeData = resumeData
                self.downloads[idx].speedBytesPerSec = 0
                self.tasks.removeValue(forKey: taskID)
                self.taskIDToItemID.removeValue(forKey: taskID)
                self.saveDownloads()
                self.updateBadgeCount()
            }
        }
    }
    
    /// Resumes a paused download from previous resume data
    /// - Parameter id: Unique identifier of the DownloadItem
    public func resumeDownload(id: String) {
        guard let idx = downloads.firstIndex(where: { $0.id == id }) else { return }
        let item = downloads[idx]
        
        let task: URLSessionDownloadTask
        if let resumeData = item.resumeData {
            task = session.downloadTask(withResumeData: resumeData)
        } else {
            task = session.downloadTask(with: item.url)
        }
        
        tasks[task.taskIdentifier] = task
        taskIDToItemID[task.taskIdentifier] = id
        
        downloads[idx].taskIdentifier = task.taskIdentifier
        downloads[idx].status = .downloading
        downloads[idx].errorMessage = nil
        
        task.resume()
        saveDownloads()
        updateBadgeCount()
    }
    
    /// Cancels and removes a download from the active queue
    /// - Parameter id: Unique identifier of the DownloadItem
    public func cancelDownload(id: String) {
        guard let idx = downloads.firstIndex(where: { $0.id == id }) else { return }
        if let taskID = downloads[idx].taskIdentifier, let task = tasks[taskID] {
            task.cancel()
            tasks.removeValue(forKey: taskID)
            taskIDToItemID.removeValue(forKey: taskID)
        }
        downloads.remove(at: idx)
        saveDownloads()
        updateBadgeCount()
    }
    
    /// Retries a failed or timed-out download
    /// - Parameter id: Unique identifier of the DownloadItem
    public func retryDownload(id: String) {
        guard let idx = downloads.firstIndex(where: { $0.id == id }) else { return }
        let item = downloads[idx]
        
        let task = session.downloadTask(with: item.url)
        tasks[task.taskIdentifier] = task
        taskIDToItemID[task.taskIdentifier] = id
        
        downloads[idx].taskIdentifier = task.taskIdentifier
        downloads[idx].status = .downloading
        downloads[idx].errorMessage = nil
        downloads[idx].progress = 0
        downloads[idx].receivedBytes = 0
        
        task.resume()
        saveDownloads()
        updateBadgeCount()
    }
    
    /// Clears all completed and cancelled download records
    public func clearCompleted() {
        downloads.removeAll { $0.status == .completed || $0.status == .cancelled }
        saveDownloads()
        updateBadgeCount()
    }
    
    // MARK: - Delegate Callbacks
    
    nonisolated func downloadDidUpdate(taskIdentifier: Int, bytesWritten: Int64, totalBytes: Int64, speed: Int64) {
        Task { @MainActor in
            guard let itemID = self.taskIDToItemID[taskIdentifier],
                  let idx = self.downloads.firstIndex(where: { $0.id == itemID }) else { return }
            
            self.downloads[idx].receivedBytes = bytesWritten
            if totalBytes > 0 {
                self.downloads[idx].totalBytes = totalBytes
                self.downloads[idx].progress = Double(bytesWritten) / Double(totalBytes)
            }
            self.downloads[idx].speedBytesPerSec = speed
        }
    }
    
    nonisolated func downloadDidFinish(taskIdentifier: Int, location: URL) {
        Task { @MainActor in
            guard let itemID = self.taskIDToItemID[taskIdentifier],
                  let idx = self.downloads.firstIndex(where: { $0.id == itemID }) else { return }
            
            let item = self.downloads[idx]
            
            do {
                if FileManager.default.fileExists(atPath: item.destinationURL.path) {
                    try FileManager.default.removeItem(at: item.destinationURL)
                }
                try FileManager.default.moveItem(at: location, to: item.destinationURL)
                
                self.downloads[idx].status = .completed
                self.downloads[idx].progress = 1.0
                self.downloads[idx].speedBytesPerSec = 0
                
                HapticManager.shared.notification(.success)
                AppState.shared.showToast("Downloaded \(item.appName)", type: .success)
            } catch {
                self.downloads[idx].status = .failed
                self.downloads[idx].errorMessage = error.localizedDescription
                HapticManager.shared.notification(.error)
            }
            
            self.tasks.removeValue(forKey: taskIdentifier)
            self.taskIDToItemID.removeValue(forKey: taskIdentifier)
            self.saveDownloads()
            self.updateBadgeCount()
        }
    }
    
    nonisolated func downloadDidFail(taskIdentifier: Int, error: Error?, resumeData: Data?) {
        Task { @MainActor in
            guard let itemID = self.taskIDToItemID[taskIdentifier],
                  let idx = self.downloads.firstIndex(where: { $0.id == itemID }) else { return }
            
            self.downloads[idx].status = .failed
            self.downloads[idx].errorMessage = error?.localizedDescription ?? "Download failed."
            self.downloads[idx].resumeData = resumeData
            self.downloads[idx].speedBytesPerSec = 0
            
            self.tasks.removeValue(forKey: taskIdentifier)
            self.taskIDToItemID.removeValue(forKey: taskIdentifier)
            self.saveDownloads()
            self.updateBadgeCount()
        }
    }
    
    // MARK: - Persistence
    
    private func saveDownloads() {
        if let data = try? JSONEncoder().encode(downloads) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadSavedDownloads() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([DownloadItem].self, from: data) {
            self.downloads = saved
        }
        updateBadgeCount()
    }
    
    private func updateBadgeCount() {
        let active = downloads.filter { $0.status == .downloading || $0.status == .queued }.count
        AppState.shared.activeDownloadsCount = active
    }
}
