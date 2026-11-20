//
//  Color+Extensions.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension Color {
    // MARK: - Semantic App Colors
    
    /// Dynamic background accommodating light and dark translucent surfaces
    static let appBackground = Color("AppBackground", bundle: nil)
    static let appCardBackground = Color("AppCardBackground", bundle: nil)
    static let appSecondaryBackground = Color("AppSecondaryBackground", bundle: nil)
    static let appBorder = Color.primary.opacity(0.08)
    
    // Status colors
    static let statusValid = Color(red: 0.18, green: 0.80, blue: 0.44)
    static let statusExpiring = Color(red: 0.98, green: 0.73, blue: 0.12)
    static let statusExpired = Color(red: 0.94, green: 0.33, blue: 0.31)
    
    // MARK: - Accent Color Palette Options
    
    public enum AccentChoice: String, CaseIterable, Identifiable {
        case sapphire = "Sapphire Blue"
        case violet = "Electric Violet"
        case indigo = "Deep Indigo"
        case coral = "Sunset Coral"
        case teal = "Cyber Teal"
        case mint = "Neo Mint"
        case crimson = "Ruby Crimson"
        
        public var id: String { rawValue }
        
        public var color: Color {
            switch self {
            case .sapphire:
                return Color(red: 0.00, green: 0.48, blue: 1.00) // Apple System Blue
            case .violet:
                return Color(red: 0.65, green: 0.30, blue: 0.95)
            case .indigo:
                return Color(red: 0.35, green: 0.34, blue: 0.84)
            case .coral:
                return Color(red: 1.00, green: 0.42, blue: 0.35)
            case .teal:
                return Color(red: 0.00, green: 0.72, blue: 0.83)
            case .mint:
                return Color(red: 0.00, green: 0.78, blue: 0.65)
            case .crimson:
                return Color(red: 0.92, green: 0.18, blue: 0.36)
            }
        }
        
        public var gradient: LinearGradient {
            switch self {
            case .sapphire:
                return LinearGradient(colors: [Color(red: 0.00, green: 0.55, blue: 1.00), Color(red: 0.10, green: 0.35, blue: 0.90)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .violet:
                return LinearGradient(colors: [Color(red: 0.72, green: 0.35, blue: 1.00), Color(red: 0.52, green: 0.20, blue: 0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .indigo:
                return LinearGradient(colors: [Color(red: 0.45, green: 0.40, blue: 0.95), Color(red: 0.25, green: 0.20, blue: 0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .coral:
                return LinearGradient(colors: [Color(red: 1.00, green: 0.50, blue: 0.40), Color(red: 0.95, green: 0.30, blue: 0.30)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .teal:
                return LinearGradient(colors: [Color(red: 0.00, green: 0.80, blue: 0.90), Color(red: 0.00, green: 0.60, blue: 0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .mint:
                return LinearGradient(colors: [Color(red: 0.10, green: 0.85, blue: 0.70), Color(red: 0.00, green: 0.68, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .crimson:
                return LinearGradient(colors: [Color(red: 1.00, green: 0.25, blue: 0.45), Color(red: 0.80, green: 0.10, blue: 0.30)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }
    
    // MARK: - Hex Initializer
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
