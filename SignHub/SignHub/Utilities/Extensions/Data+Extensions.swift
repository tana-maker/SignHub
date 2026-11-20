//
//  Data+Extensions.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation
import CommonCrypto
import CryptoKit

extension Data {
    /// Computes SHA-1 hash (used in certificate fingerprints and Mach-O CodeDirectory)
    public var sha1: Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        self.withUnsafeBytes { buffer in
            _ = CC_SHA1(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        return Data(hash)
    }
    
    /// Computes SHA-256 hash (used in modern Apple CodeDirectory slots and password hashing)
    public var sha256: Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        return Data(hash)
    }
    
    /// Hexadecimal string representation
    public var hexString: String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Colon-separated uppercase hex fingerprint (e.g., "7A:B4:9C:...")
    public var colonFormattedHex: String {
        return self.map { String(format: "%02X", $0) }.joined(separator: ":")
    }
    
    /// Initialize data from a hex string
    public init?(hexString: String) {
        let cleaned = hexString.replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard cleaned.count % 2 == 0 else { return nil }
        
        var data = Data(capacity: cleaned.count / 2)
        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let nextIndex = cleaned.index(index, offsetBy: 2)
            let byteString = cleaned[index..<nextIndex]
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        self = data
    }
}
