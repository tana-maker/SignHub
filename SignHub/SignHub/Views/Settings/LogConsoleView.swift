//
//  LogConsoleView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct LogConsoleView: View {
    @ObservedObject private var logger = AppLogger.shared
    @EnvironmentObject private var appState: AppState
    @State private var isSharingFile: Bool = false
    @State private var exportURL: URL?
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(logger.logs) { entry in
                            HStack(alignment: .top, spacing: 6) {
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
                    .padding(12)
                }
            }
            .background(Color(uiColor: .systemBackground))
        }
        .navigationTitle("Diagnostic Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        if let url = logger.exportLogsAsFile() {
                            self.exportURL = url
                            self.isSharingFile = true
                        }
                    } label: {
                        Label("Export Logs", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        logger.clearLogs()
                    } label: {
                        Label("Clear Logs", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isSharingFile) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
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
