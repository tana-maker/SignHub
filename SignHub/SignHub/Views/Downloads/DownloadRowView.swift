//
//  DownloadRowView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct DownloadRowView: View {
    public let item: DownloadItem
    @ObservedObject public var viewModel: DownloadsViewModel
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // App Icon
                if let iconURL = item.iconURL {
                    AsyncImage(url: iconURL) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Color.secondary.opacity(0.12)
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(appState.currentAccentColor.opacity(0.12))
                        Image(systemName: "doc.zipper")
                            .font(.system(size: 20))
                            .foregroundColor(appState.currentAccentColor)
                    }
                    .frame(width: 44, height: 44)
                }
                
                // Name & details
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.appName)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        switch item.status {
                        case .downloading:
                            Text("\(item.receivedBytes.formattedByteCount) of \(item.totalBytes > 0 ? item.totalBytes.formattedByteCount : "--")")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(item.speedBytesPerSec.formattedSpeedString)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(appState.currentAccentColor)
                        case .paused:
                            Text("Paused (\(item.receivedBytes.formattedByteCount))")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                        case .completed:
                            Text("Completed • \(item.totalBytes.formattedByteCount)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        case .failed:
                            Text(item.errorMessage ?? "Failed")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        case .queued:
                            Text("Queued...")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        case .cancelled:
                            Text("Cancelled")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 8) {
                    switch item.status {
                    case .downloading:
                        Button {
                            viewModel.pause(id: item.id)
                        } label: {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                    case .paused:
                        Button {
                            viewModel.resume(id: item.id)
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(appState.currentAccentColor)
                        }
                        .buttonStyle(.plain)
                        
                    case .failed:
                        Button {
                            viewModel.retry(id: item.id)
                        } label: {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                        
                    case .completed:
                        Button {
                            // Find the file in storage and trigger signing
                            let fileItem = FileItem(
                                id: item.destinationURL.lastPathComponent,
                                fileURL: item.destinationURL,
                                fileName: item.destinationURL.deletingPathExtension().lastPathComponent,
                                fileSize: item.totalBytes,
                                creationDate: Date()
                            )
                            appState.triggerSigning(for: fileItem)
                        } label: {
                            Text("Sign")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(appState.currentAccentColor))
                        }
                        .buttonStyle(.plain)
                        
                    default:
                        EmptyView()
                    }
                    
                    if item.status != .completed {
                        Button {
                            viewModel.cancel(id: item.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Progress Bar if in progress
            if item.status == .downloading || item.status == .paused {
                ProgressView(value: item.progress)
                    .tint(appState.currentAccentColor)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}
