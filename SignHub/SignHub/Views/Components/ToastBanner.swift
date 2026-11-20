//
//  ToastBanner.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public enum ToastType {
    case info
    case success
    case warning
    case error
    
    var iconName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return Color(red: 0.18, green: 0.80, blue: 0.44)
        case .warning: return Color(red: 0.98, green: 0.73, blue: 0.12)
        case .error: return Color(red: 0.94, green: 0.33, blue: 0.31)
        }
    }
}

public struct ToastMessage: Identifiable, Equatable {
    public let id = UUID()
    public let message: String
    public let type: ToastType
    public let duration: Double
    
    public init(message: String, type: ToastType = .info, duration: Double = 3.0) {
        self.message = message
        self.type = type
        self.duration = duration
    }
}

public struct ToastBannerView: View {
    public let toast: ToastMessage
    public let onDismiss: () -> Void
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.iconName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(toast.type.color)
            
            Text(toast.message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(toast.type.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
