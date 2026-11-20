//
//  AddSourceSheet.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct AddSourceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var urlString: String = ""
    @State private var isValidating: Bool = false
    @EnvironmentObject private var appState: AppState
    
    var onAdd: (URL) -> Void
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(appState.currentAccentColor.opacity(0.12))
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: "plus.circle")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(appState.currentAccentColor)
                }
                .padding(.top, 16)
                
                VStack(spacing: 8) {
                    Text("Add Repository")
                        .font(.system(size: 22, weight: .bold))
                    Text("Enter the URL of an AltStore or Scarlet compatible JSON source repository.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                TextField("https://example.com/repo.json", text: $urlString)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                
                Spacer()
                
                Button {
                    validateAndAdd()
                } label: {
                    HStack {
                        if isValidating {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 6)
                        }
                        Text("Add Source")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(urlString.isEmpty ? Color.gray : appState.currentAccentColor)
                    )
                    .padding(.horizontal, 24)
                }
                .disabled(urlString.isEmpty || isValidating)
                .minTapTarget()
                .padding(.bottom, 20)
            }
            .navigationTitle("Add Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func validateAndAdd() {
        var clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.lowercased().hasPrefix("http://") && !clean.lowercased().hasPrefix("https://") {
            clean = "https://\(clean)"
        }
        guard let url = URL(string: clean) else {
            appState.showToast("Please enter a valid URL.", type: .error)
            return
        }
        
        isValidating = true
        onAdd(url)
        dismiss()
    }
}
