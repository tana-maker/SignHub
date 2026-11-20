//
//  BackgroundRefreshTask.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation
import BackgroundTasks

/// Coordinates BGTaskScheduler background refresh for automated resigning checks
public final class BackgroundRefreshTask {
    public static let shared = BackgroundRefreshTask()
    
    private init() {}
    
    public func scheduleDailyRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: SignHubApp.backgroundRefreshTaskID)
        // Earliest trigger in 6 hours
        request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }
}
