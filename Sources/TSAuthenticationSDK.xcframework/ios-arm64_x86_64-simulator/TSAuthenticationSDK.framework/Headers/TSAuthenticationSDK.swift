//
//  TSAuthenticationSDK.swift
//  TSWebAuthnSdk
//
//  Created by Omar Ayed on 28/11/2022.
//

import UIKit


public typealias TSAuthenticationCompletion = ((Result<TSAuthenticationResult, TSAuthenticationError>) -> ())?
public typealias TSRegistrationCompletion = ((Result<TSRegistrationResult, TSAuthenticationError>) -> ())?
public typealias TSNativeBiometricsRegistrationCompletion = (Result<TSNativeBiometricsRegistrationResult, TSAuthenticationError>) -> ()
public typealias TSNativeBiometricsAuthenticationCompletion = (Result<TSNativeBiometricsAuthenticationResult, TSAuthenticationError>) -> ()
public typealias DeviceInfoCompletion = (Result<TSDeviceInfo, TSAuthenticationError>) -> Void


public enum TSPasscodeError: String {
    /// The authorization attempt failed for an unknown reason
    case unknown
    /// The user canceled the authorization attempt
    case canceled
    /// The authorization request received an invalid response
    case invalidResponse
    /// The authorization request wasn’t handled
    case notHandled
    /// The authorization attempt failed
    case failed
    /// The authorization request isn’t interactive
    case notInteractive
}

public enum TSAuthenticationError: Error, Equatable {
    /// SDK is not Initialized
    case notInitialized
    /// The domain name is invalid
    case invalidDomain
    
    case userNotFound
    case requestIsRunning
    /// Something went wrong during the registration process
    case registrationFailed
    /// Something went wrong during the authentication process
    case authenticationFailed
    /// WebAuthn session id is invalid
    case invalidWebAuthnSession
    /// Generic server error
    case genericServerError
    /// The internet connection is unavailable
    case networkError
    /// The authorization failed for a passcode error
    case passkeyError(TSPasscodeError)
    /// The authorization attempt failed for an unknown reason
    case unknown
}

public struct TSDeviceInfo: Codable {
    public let publicKeyId: String
    
    public let publicKey: String
}

final public class TSConfiguration: NSObject {

    /**
     An associated domain with the web credentials service type when making a registration or assertion request; otherwise, the request returns an error. See Supporting associated domains for more information.
     (https://developer.apple.com/documentation/xcode/supporting-associated-domains)
     */
    public private(set) var domain: String
    
    public init(domain: String) {
        self.domain = domain
    }
}


protocol TSBaseAuthenticationSdkProtocol: TSWebAuthnSdkProtocol {
    func initialize(baseUrl: String, clientId: String, configuration: TSConfiguration?)
}

final private class TSAuthenticationSDK: NSObject {

}

final public class TSAuthentication: NSObject, TSBaseAuthenticationSdkProtocol {
    
    public static let shared: TSAuthentication = TSAuthentication()
    
    private override init() {
        super.init()
    }
    
    /**
     Creates a new WebAuthn SDK instance with your client context.
     */
    public func initialize(baseUrl: String = "https://api.transmitsecurity.io/", clientId: String, configuration: TSConfiguration? = nil) {
        TSAuthenticationImpl.shared.initialize(baseUrl: baseUrl, clientId: clientId, configuration: configuration)
    }
    
    /**
     Invokes a WebAuthn credential registration, including prompting the user for biometrics.
     Upon successful completion of the registration process, this function will return a callback containing a WebAuthnEncodedResult.
     The WebAuthnEncodedResult should be used to make a completion request using your backend API which will communicate with Transmit's Service
     */
    public func register(username: String, displayName: String?, completion: TSRegistrationCompletion) {
        TSAuthenticationImpl.shared.register(username: username, displayName: displayName, completion: completion)
    }
    

    /**
     Invokes a WebAuthn credential authentication, including prompting the user for biometrics.
     If authentication is completed successfully, this function will return a callback containing a WebAuthnEncodedResult.
     The WebAuthnEncodedResult should be used to make a completion request using your backend API which will commuincate with Transmit's Service
     */
    public func authenticate(username: String, completion: TSAuthenticationCompletion = nil) {
        TSAuthenticationImpl.shared.authenticate(username: username, completion: completion)
    }
    
    
    private func registerNativeBiometrics(username: String, completion: @escaping TSNativeBiometricsRegistrationCompletion) {
        Task {
            await TSAuthenticationImpl.shared.registerNativeBiometrics(username: username, completion: completion)
        }
    }
    
    private func authenticateNativeBiometrics(username: String, challenge: String, completion: @escaping TSNativeBiometricsAuthenticationCompletion) {
        Task {
            await TSAuthenticationImpl.shared.authenticateNativeBiometrics(username: username, challenge: challenge, completion: completion)
        }
    }
    
    /**
     Invokes a WebAuthn credential sign transaction, including prompting the user for biometrics.
     If transaction signing is completed successfully, this function will return a callback containing a WebAuthnEncodedResult.
     The WebAuthnEncodedResult should be used to make a completion request using your backend API which will commuincate with Transmit's Service
     */
    public func signTransaction(username: String, completion: TSAuthenticationCompletion = nil) {
        TSAuthenticationImpl.shared.authenticate(username: username, completion: completion)
    }
    
    public func getDeviceInfo(_ completion: @escaping DeviceInfoCompletion) {
        Task {
            do {
                let deviceInfo = try await TSAuthenticationImpl.shared.deviceInfo()
                completion(.success(deviceInfo))
            } catch let error as TSAuthenticationError {
                completion(.failure(error))
            } catch {
                completion(.failure(.unknown))
            }
        }
    }
}


