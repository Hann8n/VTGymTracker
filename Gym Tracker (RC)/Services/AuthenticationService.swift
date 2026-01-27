//
//  AuthenticationService.swift
//  Gym Tracker
//
//  Created by Jack on 1/27/26.
//

import Foundation
import LocalAuthentication

/// Centralized authentication service for Face ID/Touch ID
/// Uses session-based caching to avoid repeated prompts within 5 minutes
@MainActor
class AuthenticationService {
    static let shared = AuthenticationService()
    
    // Reuse the same LAContext to enable session-based authentication caching
    // touchIDAuthenticationAllowableReuseDuration uses Apple's built-in API to cache auth for 5 minutes
    private lazy var authContext: LAContext = {
        let context = LAContext()
        // Use Apple's built-in maximum reuse duration (5 minutes) to avoid repeated prompts
        context.touchIDAuthenticationAllowableReuseDuration = LATouchIDAuthenticationMaximumAllowableReuseDuration
        return context
    }()
    
    private init() {}
    
    func authenticate(reason: String, completion: @escaping (Bool, Error?) -> Void) {
        var error: NSError?
        guard authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            DispatchQueue.main.async { completion(false, error) }
            return
        }
        authContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, err in
            DispatchQueue.main.async { completion(success, err) }
        }
    }
    
    func authenticate(reason: String) async -> Bool {
        await withCheckedContinuation { continuation in
            authenticate(reason: reason) { success, _ in continuation.resume(returning: success) }
        }
    }
    
    func isBiometricsUnavailable(error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == LAErrorDomain &&
            (nsError.code == LAError.biometryNotAvailable.rawValue ||
             nsError.code == LAError.biometryLockout.rawValue ||
             nsError.code == LAError.biometryNotEnrolled.rawValue)
    }
}
