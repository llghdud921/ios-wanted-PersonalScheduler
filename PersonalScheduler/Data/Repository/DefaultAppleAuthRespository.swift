//
//  AppleAuthRespository.swift
//  PersonalScheduler
//
//  Created by 이호영 on 2023/01/12.
//

import Foundation
import AuthenticationServices

final class DefaultAppleAuthRespository: NSObject, AppleAuthRespository {
    
    private var authcontinuation: CheckedContinuation<String, Error>?
    
    lazy var authorizationController: ASAuthorizationController = {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        return authorizationController
    }()
     
    func loginWithApple() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            authcontinuation = continuation
            authorizationController.performRequests()
        }
    }
    
    func checkAutoSign(userId: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: userId) { credentialState, error in
                switch credentialState {
                  case .authorized:
                    continuation.resume(returning: true)
                    break
                  case .revoked:
                    continuation.resume(returning: false)
                    break
                  case .notFound:
                    continuation.resume(returning: false)
                    break
                  default:
                    continuation.resume(returning: false)
                    break
                  }
            }
        }
    }
}

extension DefaultAppleAuthRespository: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            authcontinuation?.resume(returning: appleIDCredential.user)
        } else {
            authcontinuation?.resume(throwing: NetworkError.apple)
        }
        
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        authcontinuation?.resume(throwing: error)
    }
}

enum NetworkError: LocalizedError {
    case apple
}
