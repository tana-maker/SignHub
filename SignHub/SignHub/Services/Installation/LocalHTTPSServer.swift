//
//  LocalHTTPSServer.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation
import Network

#if canImport(Darwin)
import Darwin
#endif

/// Lightweight embedded server powered by Network.framework to serve manifest.plist and the signed IPA
public final class LocalHTTPSServer {
    public static let shared = LocalHTTPSServer()
    
    private var listener: NWListener?
    private var currentPort: UInt16 = 8088
    private var activeConnections: [NWConnection] = []
    
    private var manifestData: Data?
    private var ipaFileURL: URL?
    
    private init() {}
    
    /// Starts serving the specified signed IPA and its manifest on a local port
    /// - Parameters:
    ///   - signedIPAURL: Local file URL of the signed IPA
    ///   - manifestData: Serialized XML data of manifest.plist
    ///   - port: Port to bind (default 8088)
    /// - Returns: URL pointing to manifest.plist
    public func startServer(
        signedIPAURL: URL,
        manifestData: Data,
        port: UInt16 = 8088
    ) throws -> URL {
        stopServer()
        
        self.ipaFileURL = signedIPAURL
        self.manifestData = manifestData
        self.currentPort = port
        
        let params = SelfSignedCertificateGenerator.shared.configureTLSParameters()
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw NSError(domain: "SignHub", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid port number."])
        }
        
        self.listener = try NWListener(using: params, on: nwPort)
        
        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        
        listener?.start(queue: .global(qos: .userInitiated))
        
        // Return public local manifest URL
        let ipAddress = getWiFiAddress() ?? "127.0.0.1"
        guard let manifestURL = URL(string: "http://\(ipAddress):\(port)/manifest.plist") else {
            throw NSError(domain: "SignHub", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create manifest URL."])
        }
        return manifestURL
    }
    
    /// Stops the local server and cleans up active sockets
    public func stopServer() {
        for conn in activeConnections {
            conn.cancel()
        }
        activeConnections.removeAll()
        listener?.cancel()
        listener = nil
        manifestData = nil
        ipaFileURL = nil
    }
    
    private func handleConnection(_ connection: NWConnection) {
        activeConnections.append(connection)
        connection.start(queue: .global(qos: .userInitiated))
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self, weak connection] data, _, isComplete, _ in
            guard let self = self, let connection = connection, let data = data, !data.isEmpty else {
                connection?.cancel()
                return
            }
            
            let request = String(decoding: data, as: UTF8.self)
            self.routeRequest(request, on: connection)
        }
    }
    
    private func routeRequest(_ request: String, on connection: NWConnection) {
        let firstLine = request.components(separatedBy: "\r\n").first ?? ""
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            sendResponse(connection: connection, status: "400 Bad Request", body: Data())
            return
        }
        
        let path = parts[1]
        
        if path.hasPrefix("/manifest.plist") {
            if let data = self.manifestData {
                sendResponse(connection: connection, status: "200 OK", contentType: "application/xml", body: data)
            } else {
                sendResponse(connection: connection, status: "404 Not Found", body: Data())
            }
        } else if path.hasPrefix("/package.ipa") {
            if let ipaURL = self.ipaFileURL, let data = try? Data(contentsOf: ipaURL, options: .mappedIfSafe) {
                sendResponse(connection: connection, status: "200 OK", contentType: "application/octet-stream", body: data)
            } else {
                sendResponse(connection: connection, status: "404 Not Found", body: Data())
            }
        } else {
            sendResponse(connection: connection, status: "404 Not Found", body: Data())
        }
    }
    
    private func sendResponse(
        connection: NWConnection,
        status: String,
        contentType: String = "text/plain",
        body: Data
    ) {
        var responseString = "HTTP/1.1 \(status)\r\n"
        responseString += "Content-Type: \(contentType)\r\n"
        responseString += "Content-Length: \(body.count)\r\n"
        responseString += "Access-Control-Allow-Origin: *\r\n"
        responseString += "Connection: close\r\n\r\n"
        
        guard var responseData = responseString.data(using: .utf8) else {
            connection.cancel()
            return
        }
        responseData.append(body)
        
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func getWiFiAddress() -> String? {
        #if canImport(Darwin)
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" { // en0 is standard Wi-Fi on iOS
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
        #else
        return "127.0.0.1"
        #endif
    }
}
