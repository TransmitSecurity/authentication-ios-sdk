//
//  TSAuthenticationSDK.swift
//  TSWebAuthnSdk
//
//  Created by Omar Ayed on 28/11/2022.
//

import UIKit


public typealias TSAuthenticationCompletion = (Result<TSAuthenticationResult, TSAuthenticationError>) -> ()
public typealias TSRegistrationCompletion = (Result<TSRegistrationResult, TSAuthenticationError>) -> ()
public typealias TSNativeBiometricsRegistrationCompletion = (Result<TSNativeBiometricsRegistrationResult, TSAuthenticationError>) -> ()
public typealias TSNativeBiometricsAuthenticationCompletion = (Result<TSNativeBiometricsAuthenticationResult, TSAuthenticationError>) -> ()
public typealias DeviceInfoCompletion = (Result<TSDeviceInfo, TSAuthenticationError>) -> Void
public typealias TSTOTPRegistrationCompletion = (Result<TSTOTPRegistrationResult, TSAuthenticationError>) -> ()
public typealias TSTOTPGenerateCodeCompletion = (Result<TSTOTPGenerateCodeResult, TSAuthenticationError>) -> ()


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

extension TSTOTPError: Equatable {
    public static func == (lhs: TSTOTPError, rhs: TSTOTPError) -> Bool {
        switch (lhs, rhs) {
        case (.notRegistered, .notRegistered):
            return true
        case (.invalidSecret, .invalidSecret):
            return true
        case (.invalidAlgorithm, .invalidAlgorithm):
            return true
        case (.invalidPeriod, .invalidPeriod):
            return true
        case (.invalidDigits, .invalidDigits):
            return true
        case (.nativeBiometricsNotAvailable, .nativeBiometricsNotAvailable):
            return true
        case (.internal, .internal):
            return true
        default:
            return false
        }
    }
}

public enum TSTOTPError: Error {
    /// The native biometrics is unavailable or not enrolled
    case nativeBiometricsNotAvailable
    /// The TOTP URI format is incorrect
    case incorrectURIFormat
    /// TOTP wasn't registered
    case notRegistered
    /// The secret key in the TOTP URI is either missing or has an incorrect format.
    case invalidSecret
    /// The algorithm in the TOTP URI is either missing or has an incorrect format.
    case invalidAlgorithm
    /// The period in the TOTP URI is either missing or has an incorrect format.
    case invalidPeriod
    /// The digits in the TOTP URI is either missing or has an incorrect format.
    case invalidDigits
    /// Internal error
    case `internal`(Error?)
}

public enum TSNativeBiometricsError: Error {
    /// The native biometrics is unavailable or not enrolled
    case nativeBiometricsNotAvailable
    /// Native biometrics wasn't registered
    case notRegistered
    /// Internal keychain error
    case `internal`(Error?)
}

extension TSNativeBiometricsError: Equatable {
    public static func == (lhs: TSNativeBiometricsError, rhs: TSNativeBiometricsError) -> Bool {
        switch (lhs, rhs) {
        case (.nativeBiometricsNotAvailable, .nativeBiometricsNotAvailable):
            return true
        case (.notRegistered, .notRegistered):
            return true
        case (.internal, .internal):
            return true
        default:
            return false
        }
    }
}

public enum TSAuthenticationError: Error, Equatable {
    /// SDK is not Initialized
    case notInitialized
    /// The functionality is not supported in the current iOS version.
    case unsupportedOSVersion
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
    /// TOTP errors
    case totpError(TSTOTPError)
    /// Native Biometrics errors
    case nativeBiometricsError(TSNativeBiometricsError)
    
    /// The authorization attempt failed for an unknown reason
    case unknown
}

public enum TSTOTPSecurityType: Codable {
    case biometric
    
    case none
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


protocol TSBaseAuthenticationSdkProtocol {
    func initialize(baseUrl: String, clientId: String, configuration: TSConfiguration?)
    
    func getDeviceInfo(_ completion: @escaping DeviceInfoCompletion)
    
    static func isWebAuthnSupported() -> Bool
}

final public class TSAuthentication: NSObject, TSBaseAuthenticationSdkProtocol {

    
    public static let shared: TSAuthentication = TSAuthentication()
    
    private var controller: TSAuthenticationController?
    
    private override init() {
        super.init()
    }
    
    /**
     Creates a new WebAuthn SDK instance with your client context.
     */
    public func initialize(baseUrl: String = "https://api.transmitsecurity.io/", clientId: String, configuration: TSConfiguration? = nil) {
        guard controller == nil else { return }
        
        let controller = TSAuthenticationController()
        
        controller.initialize(baseUrl: baseUrl, clientId: clientId, configuration: configuration)
        
        self.controller = controller
    }
    
    /**
     Invokes a WebAuthn credential registration, including prompting the user for biometrics.
     Upon successful completion of the registration process, this function will return a callback containing a WebAuthnEncodedResult.
     The WebAuthnEncodedResult should be used to make a completion request using your backend API which will communicate with Transmit's Service
     */
    public func registerWebAuthn(username: String, displayName: String?, completion: TSRegistrationCompletion?) {
        guard let controller else { completion?(.failure(.notInitialized)); return }
        
        controller.register(username: username, displayName: displayName, completion: completion)
    }
    
    /**
     Invokes a WebAuthn credential authentication, including prompting the user for biometrics.
     If authentication is completed successfully, this function will return a callback containing a WebAuthnEncodedResult.
     The WebAuthnEncodedResult should be used to make a completion request using your backend API which will commuincate with Transmit's Service
     */
    public func authenticateWebAuthn(username: String, completion: TSAuthenticationCompletion? = nil) {
        guard let controller else { completion?(.failure(.notInitialized)); return }
        
        controller.authenticate(username: username, completion: completion)
    }
    
    /**
     Invokes a WebAuthn credential sign transaction, including prompting the user for biometrics.
     If transaction signing is completed successfully, this function will return a callback containing a WebAuthnEncodedResult.
     The WebAuthnEncodedResult should be used to make a completion request using your backend API which will commuincate with Transmit's Service
     */
    public func signWebauthnTransaction(username: String, completion: TSAuthenticationCompletion? = nil) {
        guard let controller else { completion?(.failure(.notInitialized)); return }
        
        controller.authenticate(username: username, completion: completion)
    }
    
    private func registerNativeBiometrics(username: String, completion: @escaping TSNativeBiometricsRegistrationCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        Task {
            await controller.registerNativeBiometrics(username: username, completion: completion)
        }
    }
    
    private func authenticateNativeBiometrics(username: String, challenge: String, completion: @escaping TSNativeBiometricsAuthenticationCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        Task {
            await controller.authenticateNativeBiometrics(username: username, challenge: challenge, completion: completion)
        }
    }
    
    /**
    Registers a TOTP authenticatior.

    - Parameters:
      - URI: A TOTP URI string a standardized way to represent the parameters needed for TOTP authentication. The URI contains essential information required for generating one-time passwords. The TOTP URI needs to follow this format: otpauth://totp/{issuer}:{label}?secret={base32-secret}&issuer={issuer}&algorithm={algorithm}&digits={digits}&period={period}.
      - securityType: Specifies the method of protecting the stored TOTP secret. Options include `none` for no additional protection or `biometric` for securing the secret with biometric authentication, adding an extra layer of security.
      - completion: The callback containing either error or completion result. Response object containing: ISSUER, LABEL, and UUID.
        ISSUER: The issuer or organization's name (e.g., "MyApp").
        LABEL:  The user account label (e.g., "johndoe@example.com", "John", "+972505555555").
        UUID:   The unique identifier for which the registration data is stored, it should be provided for generation of TOTP code.
    */
    public func registerTOTP(URI: String, securityType: TSTOTPSecurityType, completion: @escaping TSTOTPRegistrationCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        controller.registerTOTP(URI: URI, securityType: securityType, completion: completion)
    }
    
    /**
     Generates a Time-based One-Time Password (TOTP) code.

     This function implements the TOTP algorithm specified in RFC 6238 to produce a temporary, time-sensitive password based on a shared secret and the current time. The generated code is valid for a short period, usually 30 to 60 seconds, after which a new code will be generated.

     - Parameters:
       - UUID: The unique identifier for which the registration data is stored.
       - completion: The callback containing either error or result object contaiting generated TOTP code.
    */
    public func generateTOTPCode(UUID: String, completion: @escaping TSTOTPGenerateCodeCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        controller.generateTOTPCode(UUID: UUID, completion: completion)
    }

    
    public func getDeviceInfo(_ completion: @escaping DeviceInfoCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        controller.getDeviceInfo(completion)
    }
    
    /**
     Checks if the WebAuthn feature is supported on the current iOS version.
     @return
     `true` if passkeys are supported, `false` otherwise.
     */
    public static func isWebAuthnSupported() -> Bool {
        TSAuthenticationController.isWebAuthnSupported()
    }
}


