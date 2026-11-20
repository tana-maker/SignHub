//
//  KeychainService.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation
import Security

/// Thread-safe wrapper around the iOS Security Keychain API
public final class KeychainService {
    public static let shared = KeychainService()
    
    private let serviceName = "com.signhub.keychain"
    
    private init() {}
    
    /// Stores password string in Keychain
    public func savePassword(_ password: String, forAccount account: String) -> Bool {
        guard let data = password.data(using: .utf8) else { return false }
        return save(data: data, forAccount: account)
    }
    
    /// Retrieves password string from Keychain
    public func getPassword(forAccount account: String) -> String? {
        guard let data = getData(forAccount: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Stores arbitrary binary data in Keychain
    public func save(data: Data, forAccount account: String) -> Bool {
        // Delete existing item first
        delete(forAccount: account)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieves data from Keychain
    public func getData(forAccount account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return data
        }
        return nil
    }
    
    /// Deletes item from Keychain
    @discardableResult
    public func delete(forAccount account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
