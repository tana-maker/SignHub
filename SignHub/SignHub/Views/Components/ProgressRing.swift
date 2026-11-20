//
//  ProgressRing.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

/// Animated circular progress ring with status indication and smooth transitions
public struct ProgressRing: View {
    public var progress: Double // 0.0 to 1.0
    public var lineWidth: CGFloat = 4
    public var size: CGFloat = 32
    public var accentColor: Color = .blue
    public var isIndeterminate: Bool = false
    
    @State private var rotation: Double = 0
    
    public init(
        progress: Double = 0.0,
        lineWidth: CGFloat = 4,
        size: CGFloat = 32,
        accentColor: Color = .blue,
        isIndeterminate: Bool = false
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.accentColor = accentColor
        self.isIndeterminate = isIndeterminate
    }
    
    public var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(accentColor.opacity(0.2), lineWidth: lineWidth)
            
            if isIndeterminate {
                Circle()
                    .trim(from: 0.1, to: 0.8)
                    .stroke(
                        accentColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            } else {
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(progress, 0.0), 1.0)))
                    .stroke(
                        accentColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.25), value: progress)
            }
        }
        .frame(width: size, height: size)
    }
}
