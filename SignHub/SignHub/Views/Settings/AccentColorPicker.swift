//
//  AccentColorPicker.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct AccentColorPicker: View {
    @Binding public var selectedAccent: Color.AccentChoice
    
    let columns = [
        GridItem(.adaptive(minimum: 44, maximum: 54), spacing: 14)
    ]
    
    public var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(Color.AccentChoice.allCases) { choice in
                let isSelected = selectedAccent == choice
                Button {
                    HapticManager.shared.impact(.light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedAccent = choice
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(choice.gradient)
                            .frame(width: 44, height: 44)
                            .shadow(color: choice.color.opacity(0.3), radius: 6, x: 0, y: 3)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(choice.rawValue)
            }
        }
        .padding(.vertical, 8)
    }
}
