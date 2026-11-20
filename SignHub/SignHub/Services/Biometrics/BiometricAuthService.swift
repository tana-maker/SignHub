//
//  BiometricAuthService.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation
import LocalAuthentication

/// Service encapsulating Face ID / Touch ID authentication
public final class BiometricAuthService {
    public static let shared = BiometricAuthService()
    
    public enum BiometricType {
        case none
        case touchID
        case faceID
    }
    
    private init() {}
    
    /// Detects hardware biometric capability
    public var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        default: return .none
        }
    }
    
    /// Authenticates using biometrics with passcode fallback
    public func authenticateUser(reason: String = "Authenticate to access SignHub") async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return true // Fallback if no device passcode configured
        }
        
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}
