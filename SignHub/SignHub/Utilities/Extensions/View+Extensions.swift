//
//  View+Extensions.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

// MARK: - Glassmorphism Card Modifier

public struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var strokeOpacity: Double = 0.12
    var shadowRadius: CGFloat = 8
    var shadowY: CGFloat = 4
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(strokeOpacity * 1.8),
                                Color.white.opacity(strokeOpacity * 0.4),
                                Color.black.opacity(strokeOpacity * 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.06), radius: shadowRadius, x: 0, y: shadowY)
    }
}

// MARK: - Shimmer / Skeleton Animation Modifier

public struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1.0
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.35),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .rotationEffect(.degrees(25))
                    .offset(x: phase * geometry.size.width * 2)
                    .frame(width: geometry.size.width * 2, height: geometry.size.height * 2)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1.0
                }
            }
    }
}

// MARK: - Touch Target & Accessibility Helpers

public extension View {
    /// Applies a standard 20pt rounded glass card effect
    func glassCard(cornerRadius: CGFloat = 20, strokeOpacity: Double = 0.12) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, strokeOpacity: strokeOpacity))
    }
    
    /// Applies an animated shimmer skeleton effect
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
    
    /// Ensures compliance with Apple's 44x44pt minimum tap target
    func minTapTarget() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
    
    /// Dismiss keyboard utility
    func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}
