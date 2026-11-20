//
//  DownloadsViewModel.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI
import Combine

@MainActor
public final class DownloadsViewModel: ObservableObject {
    @Published public var downloadManager = DownloadManager.shared
    @Published public var isShowingAddDownloadSheet: Bool = false
    
    public init() {}
    
    public var activeDownloads: [DownloadItem] {
        downloadManager.downloads.filter { $0.status == .downloading || $0.status == .queued || $0.status == .paused }
    }
    
    public var completedDownloads: [DownloadItem] {
        downloadManager.downloads.filter { $0.status == .completed || $0.status == .failed || $0.status == .cancelled }
    }
    
    public func startNewDownload(url: URL, appName: String) {
        downloadManager.startDownload(url: url, appName: appName)
    }
    
    public func pause(id: String) {
        downloadManager.pauseDownload(id: id)
    }
    
    public func resume(id: String) {
        downloadManager.resumeDownload(id: id)
    }
    
    public func cancel(id: String) {
        downloadManager.cancelDownload(id: id)
    }
    
    public func retry(id: String) {
        downloadManager.retryDownload(id: id)
    }
    
    public func clearCompleted() {
        downloadManager.clearCompleted()
    }
}
