//
//  BackgroundDownloadDelegate.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// Delegate protocol to communicate download events back to DownloadManager
protocol DownloadManagerDelegate: AnyObject {
    func downloadDidUpdate(taskIdentifier: Int, bytesWritten: Int64, totalBytes: Int64, speed: Int64)
    func downloadDidFinish(taskIdentifier: Int, location: URL)
    func downloadDidFail(taskIdentifier: Int, error: Error?, resumeData: Data?)
}

/// URLSession download delegate handling background session callbacks
final class BackgroundDownloadDelegate: NSObject, URLSessionDownloadDelegate {
    weak var delegate: DownloadManagerDelegate?
    
    // Speed tracking
    private var lastBytesMap: [Int: (bytes: Int64, time: Date)] = [:]
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let taskID = downloadTask.taskIdentifier
        let now = Date()
        
        var speed: Int64 = 0
        if let last = lastBytesMap[taskID] {
            let elapsed = now.timeIntervalSince(last.time)
            if elapsed >= 0.5 { // recalculate speed every 500ms
                let deltaBytes = totalBytesWritten - last.bytes
                speed = Int64(Double(deltaBytes) / elapsed)
                lastBytesMap[taskID] = (totalBytesWritten, now)
            }
        } else {
            lastBytesMap[taskID] = (totalBytesWritten, now)
        }
        
        delegate?.downloadDidUpdate(
            taskIdentifier: taskID,
            bytesWritten: totalBytesWritten,
            totalBytes: totalBytesExpectedToWrite,
            speed: speed
        )
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let taskID = downloadTask.taskIdentifier
        lastBytesMap.removeValue(forKey: taskID)
        delegate?.downloadDidFinish(taskIdentifier: taskID, location: location)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let taskID = task.taskIdentifier
        lastBytesMap.removeValue(forKey: taskID)
        
        var resumeData: Data? = nil
        if let error = error as NSError?,
           let data = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            resumeData = data
        }
        
        if error != nil {
            delegate?.downloadDidFail(taskIdentifier: taskID, error: error, resumeData: resumeData)
        }
    }
}
