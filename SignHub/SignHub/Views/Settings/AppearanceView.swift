//
//  AppearanceView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct AppearanceView: View {
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        List {
            Section(header: Text("Theme Mode")) {
                Picker("Theme Mode", selection: $appState.appearanceMode) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
            }
            
            Section(header: Text("Accent Color")) {
                AccentColorPicker(selectedAccent: $appState.accentChoice)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
