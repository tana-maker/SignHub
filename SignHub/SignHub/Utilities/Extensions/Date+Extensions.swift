//
//  Date+Extensions.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

extension Date {
    /// Formats as relative time (e.g. "3 hours ago", "yesterday")
    public var relativeFormattedString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Formats as standard short date (e.g. "Nov 20, 2026")
    public var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Expiry status string (e.g. "Expires in 45 days", "Expired 2 days ago")
    public var expiryCountdownString: String {
        let calendar = Calendar.current
        let now = Date()
        
        if self < now {
            let components = calendar.dateComponents([.day, .hour], from: self, to: now)
            let days = components.day ?? 0
            if days == 0 {
                return "Expired today"
            } else if days == 1 {
                return "Expired yesterday"
            } else {
                return "Expired \(days) days ago"
            }
        } else {
            let components = calendar.dateComponents([.day, .hour], from: now, to: self)
            let days = components.day ?? 0
            let hours = components.hour ?? 0
            
            if days > 1 {
                return "Expires in \(days) days"
            } else if days == 1 {
                return "Expires in 1 day \(hours)h"
            } else if hours > 0 {
                return "Expires in \(hours) hours"
            } else {
                return "Expires in less than an hour"
            }
        }
    }
    
    /// Number of full days remaining until this date
    public var daysRemaining: Int {
        let calendar = Calendar.current
        let startOfNow = calendar.startOfDay(for: Date())
        let startOfTarget = calendar.startOfDay(for: self)
        let components = calendar.dateComponents([.day], from: startOfNow, to: startOfTarget)
        return components.day ?? 0
    }
    
    /// True if date is within 30 days of now and not yet expired
    public var isExpiringSoon: Bool {
        let days = daysRemaining
        return days >= 0 && days <= 30
    }
    
    /// True if date has already passed
    public var isPast: Bool {
        return self < Date()
    }
}
