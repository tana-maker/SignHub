//
//  NotificationManager.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation
import UserNotifications

/// Handles scheduling local notifications prior to certificate expiry
public final class NotificationManager {
    public static let shared = NotificationManager()
    
    private init() {}
    
    /// Requests notification permission from user
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }
    
    /// Checks all installed applications and certificates and schedules expiry reminder notifications
    public func checkCertificatesAndNotify() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }
        
        // Remove old notifications
        center.removeAllPendingNotificationRequests()
        
        let apps = await SignedAppsViewModel.shared.installedApps
        for app in apps {
            guard !app.isExpired else { continue }
            
            // Schedule at 7 days, 3 days, 1 day, and 2 hours before expiry
            let intervals: [(days: Int, hours: Int)] = [
                (7, 0),
                (3, 0),
                (1, 0),
                (0, 2)
            ]
            
            for interval in intervals {
                let targetDate = Calendar.current.date(
                    byAdding: .second,
                    value: -(interval.days * 86400 + interval.hours * 3600),
                    to: app.expiryDate
                )
                
                guard let scheduledDate = targetDate, scheduledDate > Date() else { continue }
                
                let content = UNMutableNotificationContent()
                content.title = "App Expiring Soon: \(app.name)"
                if interval.days > 0 {
                    content.body = "\(app.name) will expire in \(interval.days) day(s). Open SignHub to re-sign it."
                } else {
                    content.body = "\(app.name) will expire in \(interval.hours) hour(s). Re-sign now to prevent crashes."
                }
                content.sound = .default
                
                let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                
                let requestID = "cert_expiry_\(app.id)_\(interval.days)d_\(interval.hours)h"
                let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
                
                try? await center.add(request)
            }
        }
    }
}
