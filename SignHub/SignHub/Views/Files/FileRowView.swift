//
//  FileRowView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct FileRowView: View {
    public let item: FileItem
    public var isEditMode: Bool
    public var isSelected: Bool
    public var onInspect: () -> Void
    public var onSign: () -> Void
    public var onRename: () -> Void
    public var onDelete: () -> Void
    
    @EnvironmentObject private var appState: AppState
    @State private var isShowingShareSheet: Bool = false
    
    public var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(appState.currentAccentColor.opacity(0.12))
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 22))
                    .foregroundColor(appState.currentAccentColor)
            }
            .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.fileName)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(item.fileSize.formattedByteCount)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(item.creationDate.shortDateString)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if !isEditMode {
                Menu {
                    Button {
                        HapticManager.shared.impact(.medium)
                        onSign()
                    } label: {
                        Label("Sign & Install", systemImage: "signature")
                    }
                    
                    Button {
                        onInspect()
                    } label: {
                        Label("Inspect Info & Entitlements", systemImage: "info.circle")
                    }
                    
                    Button {
                        isShowingShareSheet = true
                    } label: {
                        Label("Share File", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        onRename()
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(4)
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .leading) {
            Button {
                onSign()
            } label: {
                Label("Sign", systemImage: "signature")
            }
            .tint(appState.currentAccentColor)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                isShowingShareSheet = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareSheet(items: [item.fileURL])
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
