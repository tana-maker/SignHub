//
//  CertificateDetailView.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import SwiftUI

public struct CertificateDetailView: View {
    public let certificate: CertificateModel
    @ObservedObject public var viewModel: CertificateManagerViewModel
    @EnvironmentObject private var appState: AppState
    
    public var body: some View {
        List {
            // Summary Card
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(certificate.name)
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                        if certificate.isDefault {
                            Text("DEFAULT")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(appState.currentAccentColor))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text(certificate.teamName)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text(certificate.expiryDate.expiryCountdownString)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(certificate.status == .valid ? .green : (certificate.status == .expiringSoon ? .orange : .red))
                }
                .padding(.vertical, 6)
            }
            
            // Actions
            Section {
                if !certificate.isDefault {
                    Button {
                        viewModel.setDefault(certificate: certificate)
                    } label: {
                        Label("Set as Default Certificate", systemImage: "star.fill")
                            .foregroundColor(appState.currentAccentColor)
                    }
                }
            }
            
            // Details
            Section(header: Text("Certificate Information")) {
                LabeledContent("Team ID", value: certificate.teamIdentifier)
                LabeledContent("Common Name", value: certificate.commonName)
                LabeledContent("Expires On", value: certificate.expiryDate.shortDateString)
                if let serial = certificate.serialNumber {
                    LabeledContent("Serial Number", value: serial)
                }
                if let fp = certificate.sha1Fingerprint {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SHA-1 Fingerprint")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(fp)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // Provisioned Devices (UDID)
            Section(header: Text("Provisioned Devices (\(certificate.isEnterprise ? "Wildcard / Enterprise" : "\(certificate.provisionedUDIDs.count)"))")) {
                if certificate.isEnterprise {
                    Text("This certificate is Enterprise / In-House and can install on any iOS device without device UDID registration.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                } else if certificate.provisionedUDIDs.isEmpty {
                    Text("No UDIDs listed in provisioning profile.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(certificate.provisionedUDIDs, id: \.self) { udid in
                        Text(udid)
                            .font(.system(size: 11, design: .monospaced))
                    }
                }
            }
            
            // Entitlements
            Section(header: Text("Entitlements")) {
                if certificate.entitlements.isEmpty {
                    Text("No entitlements")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(certificate.entitlements.sorted(by: { $0.key < $1.key }), id: \.key) { key, val in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(key)
                                .font(.system(size: 13, weight: .semibold))
                            Text(val)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Certificate Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}
