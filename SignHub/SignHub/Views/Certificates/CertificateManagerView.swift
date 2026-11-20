//
//  CertificateManagerView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct CertificateManagerView: View {
    @StateObject private var viewModel = CertificateManagerViewModel()
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        List {
            if viewModel.certificates.isEmpty {
                EmptyStateView(
                    iconName: "person.badge.shield.checkmark",
                    title: "No Certificates Imported",
                    subtitle: "Import your .p12 certificate and .mobileprovision file to sign applications on this device.",
                    actionTitle: "Import Certificate",
                    accentColor: appState.currentAccentColor
                ) {
                    viewModel.isShowingImportSheet = true
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else {
                Section {
                    ForEach(viewModel.certificates) { cert in
                        NavigationLink(destination: CertificateDetailView(certificate: cert, viewModel: viewModel)) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(statusColor(for: cert.status).opacity(0.15))
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(statusColor(for: cert.status))
                                }
                                .frame(width: 44, height: 44)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(cert.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        if cert.isDefault {
                                            Text(LocalizedStrings.certDefaultBadge)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(appState.currentAccentColor))
                                        }
                                    }
                                    
                                    Text(cert.teamName)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 6) {
                                        Text(cert.status.rawValue)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(statusColor(for: cert.status))
                                        
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        
                                        Text(cert.expiryDate.expiryCountdownString)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: viewModel.deleteCertificate)
                } header: {
                    Text("Installed Certificates (\(viewModel.certificates.count))")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(LocalizedStrings.certManagerTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.isShowingImportSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingImportSheet) {
            ImportCertificateSheet(viewModel: viewModel)
        }
    }
    
    private func statusColor(for status: CertificateStatus) -> Color {
        switch status {
        case .valid: return Color.statusValid
        case .expiringSoon: return Color.statusExpiring
        case .expired: return Color.statusExpired
        }
    }
}
