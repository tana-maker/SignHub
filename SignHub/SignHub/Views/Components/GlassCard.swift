//
//  GlassCard.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

/// Reusable glassmorphic card container with rounded corners and subtle shadow
public struct GlassCard<Content: View>: View {
    public var cornerRadius: CGFloat = 20
    public var padding: CGFloat = 16
    @ViewBuilder public var content: () -> Content
    
    public init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(padding)
        .glassCard(cornerRadius: cornerRadius)
    }
}
