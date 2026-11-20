//
//  SelfSignedCertificateGenerator.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation
import Security
import Network

/// Manages ephemeral TLS parameters for Network.framework NWListener
public final class SelfSignedCertificateGenerator {
    public static let shared = SelfSignedCertificateGenerator()
    
    private init() {}
    
    /// Configures NWParameters for local TLS listener
    public func configureTLSParameters() -> NWParameters {
        let tcpOptions = NWProtocolTCP.Options()
        let params = NWParameters(tls: nil, tcp: tcpOptions)
        params.allowLocalEndpointReuse = true
        params.includePeerToPeer = true
        return params
    }
}
