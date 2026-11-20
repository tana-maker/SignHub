//
//  SigningConsoleView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

/// Live terminal-style log console streaming code signing progress
public struct SigningConsoleView: View {
    @ObservedObject public var viewModel: SigningViewModel
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(appState.currentAccentColor)
                    Text("Signing IPA...")
                        .font(.system(size: 16, weight: .bold))
                }
                Spacer()
                Text("\(viewModel.logs.count) events")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            
            Divider()
            
            // Console Terminal Output
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(viewModel.logs) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Text(entry.formattedTimestamp)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Text("[\(entry.level.rawValue)]")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(colorForLevel(entry.level))
                                
                                Text(entry.message)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            .id(entry.id)
                        }
                    }
                    .padding(14)
                }
                .onChange(of: viewModel.logs.count) { _ in
                    if let lastID = viewModel.logs.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color(uiColor: .systemBackground))
        }
    }
    
    private func colorForLevel(_ level: LogLevel) -> Color {
        switch level {
        case .info: return .blue
        case .debug: return .gray
        case .warning: return .orange
        case .error: return .red
        case .success: return .green
        }
    }
}
