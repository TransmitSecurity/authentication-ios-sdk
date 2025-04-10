//
//  TSAuthenticationSDK.swift
//  TSWebAuthnSdk
//
//  Created by Omar Ayed on 28/11/2022.
//

import UIKit
import TSCoreSDK


public typealias TSAuthenticationCompletion = (Result<TSAuthenticationResult, TSAuthenticationError>) -> ()
public typealias TSRegistrationCompletion = (Result<TSRegistrationResult, TSAuthenticationError>) -> ()
public typealias TSNativeBiometricsRegistrationCompletion = (Result<TSNativeBiometricsRegistrationResult, TSAuthenticationError>) -> ()
public typealias TSNativeBiometricsAuthenticationCompletion = (Result<TSNativeBiometricsAuthenticationResult, TSAuthenticationError>) -> ()
public typealias TSNativeBiometricsUnregisterCompletion = (Result<TSNativeBiometricsUnregisterResult, TSAuthenticationError>) -> ()
public typealias DeviceInfoCompletion = (Result<TSDeviceInfo, TSAuthenticationError>) -> Void
public typealias TSTOTPRegistrationCompletion = (Result<TSTOTPRegistrationResult, TSAuthenticationError>) -> ()
public typealias TSTOTPGenerateCodeCompletion = (Result<TSTOTPGenerateCodeResult, TSAuthenticationError>) -> ()
public typealias TSApprovalCompletion = (Result<TSAuthenticationResult, TSAuthenticationError>) -> ()
public typealias TSNativeBiometricsApprovalCompletion = (Result<TSNativeBiometricsAuthenticationResult, TSAuthenticationError>) -> ()
public typealias TSSignChallengeCompletion = (Result<TSSignChallengeResult, TSAuthenticationError>) -> Void

/// Alternate paths used by the SDK to route API calls to your proxy server.
public struct WebAuthnApis: Codable {
    
    let startAuthentication: String
    
    let startRegistration: String
    
    public init(startAuthentication: String, startRegistration: String) {
        self.startAuthentication = startAuthentication
        self.startRegistration = startRegistration
    }
}

/// Initialization options for WebAuthn.
public struct TSAuthenticationInitOptions: Codable {
    /// Override endpoints when using a proxy server in case the proxy server implements its own paths.
    let webAuthnApiPaths: WebAuthnApis
    
    public init(webAuthnApiPaths: WebAuthnApis) {
        self.webAuthnApiPaths = webAuthnApiPaths
    }
}

/**
 Additional configuration for SDK initialization.
 */
public struct TSAuthenticationConfiguration {
    let configurationFileName: String
    
    public init(configurationFileName: String) {
        self.configurationFileName = configurationFileName
    }
}

public enum TSTOTPSecurityType: Codable {
    /** 
     Securing the secret with biometric authentication, adding an extra layer of security.
     */
    case biometric
    /**
     No additional protection for secret
     */
    case none
}

public struct TSDeviceInfo: Codable {
    public let publicKeyId: String
    
    public let publicKey: String
}

protocol TSBaseAuthenticationSdkProtocol {
    func initialize(baseUrl: String, clientId: String, domain: String?, initOptions: TSAuthenticationInitOptions?)
    
    func getDeviceInfo(_ completion: @escaping DeviceInfoCompletion)
    
    static func isWebAuthnSupported() -> Bool
}

final public class TSAuthentication: NSObject, TSBaseAuthenticationSdkProtocol, TSLogConfigurable {

    
    public static let shared: TSAuthentication = TSAuthentication()
    
    private var controller: TSAuthenticationController?
    
    private override init() {
        super.init()
    }
    
    private struct Constants {
        struct Plist {
            static let fileName = "TransmitSecurity"
        }
    }
    
    /**
     Creates a new SDK instance with your client context.
     */
    public func initialize(baseUrl: String = "https://api.transmitsecurity.io/", clientId: String, domain: String? = nil, initOptions: TSAuthenticationInitOptions? = nil) {
        guard controller == nil else { return }
        
        let controller = TSAuthenticationController()
        
        controller.initialize(baseUrl: baseUrl,
                              clientId: clientId,
                              domain: domain,
                              initOptions: initOptions)
        
        self.controller = controller
    }
    
        
    /**
     Creates a new SDK instance with your client context.
     Credentials are configured from TransmitSecurity.plist file
     */
    public func initializeSDK(configuration: TSAuthenticationConfiguration? = nil) throws {
        guard controller == nil else { return }
        
        let controller = TSAuthenticationController()
        let configFileName = configuration?.configurationFileName ?? Constants.Plist.fileName
        do {
            let fileData = try TSFile.readFromAppPlist(named: configFileName, as: PlistRoot.self)
            controller.initialize(baseUrl: fileData.credentials.baseUrl,
                                  clientId: fileData.credentials.clientId,
                                  domain: fileData.credentials.domain,
                                  initOptions: fileData.initOptions)
            self.controller = controller
        } catch {
            throw TSAuthenticationError.initializationError
        }
     
    }
    
    /**
     Invokes a WebAuthn credential registration, including prompting the user for biometrics.
     Upon successful completion of the registration process, this function will return a callback containing a WebAuthnEncodedResult.
     The WebAuthnEncodedResult should be used to make a completion request using your backend API which will communicate with Transmit's Service
     */
    public func registerWebAuthn(username: String, displayName: String?, completion: TSRegistrationCompletion?) {
        guard let controller else { completion?(.failure(.notInitialized)); return }
        // 1. webauthn-registration: start registration
        controller.register(username: username, displayName: displayName, completion: completion)
    }
    
    /**
     Initiates the client-side WebAuthn credential registration process using parameters provided by the backend.
     - Parameter webAuthnRegistrationData: The JSON response object received from your backend containing the necessary data to initiate the WebAuthn registration on the client device.
     - Parameter completion: An optional closure that is called asynchronously upon the completion (either success or failure) of the WebAuthn registration attempt.
     */
    public func registerWebAuthn(_ webAuthnRegistrationData: TSWebAuthnRegistrationData, completion: TSRegistrationCompletion?) {
        guard let controller else { completion?(.failure(.notInitialized)); return }
        // 1. webauthn-registration: start registration
        controller.register(webAuthnRegistrationData, completion: completion)
    }
    
    /**
     Invokes a WebAuthn credential authentication, including prompting the user for biometrics.
     If authentication is completed successfully, this function will return a callback containing a WebAuthnEncodedResult.
     The WebAuthnEncodedResult should be used to make a completion request using your backend API which will commuincate with Transmit's Service
     */
    public func authenticateWebAuthn(username: String, options: TSAuthentication.WebAuthnAuthenticationOptions = [], completion: TSAuthenticationCompletion? = nil) {
        guard let controller else { completion?(.failure(.notInitialized)); return }
        
        controller.authenticate(username: username, options: options, completion: completion)
    }
    
    /**
     Invokes a WebAuthn credential authentication, including prompting the user for biometrics.
     - Parameter webAuthnAuthenticationData: The JSON response object received from your backend containing the necessary data to initiate the WebAuthn authentication on the client device.
     - Parameter completion: A closure that is called asynchronously upon the completion (success or failure) of the WebAuthn authentication attempt.
     */
    public func authenticateWebAuthn(_ webAuthnAuthenticationData: TSWebAuthnAuthenticationData, options: TSAuthentication.WebAuthnAuthenticationOptions = [], completion: TSAuthenticationCompletion? = nil) {
        guard let controller else { completion?(.failure(.notInitialized)); return }
        
        controller.authenticate(webAuthnAuthenticationData, options: options, completion: completion)
    }
    
    /**
     Invokes a WebAuthn credential signing transaction, including prompting the user for biometrics.
     If transaction signing is completed successfully, this function will return a callback containing a WebAuthnEncodedResult.
     The WebAuthnEncodedResult should be used to make a completion request using your backend API which will commuincate with Transmit's Service
     */
    public func signWebauthnTransaction(username: String, options: TSAuthentication.WebAuthnAuthenticationOptions = [], completion: TSAuthenticationCompletion? = nil) {
        guard let controller else { completion?(.failure(.notInitialized)); return }
        
        controller.authenticate(username: username, options: options, completion: completion)
    }
    
    /**
     Initiates a WebAuthn credential signing transaction, typically prompting the user for biometrics or a security key.
     - Parameter webAuthnAuthenticationData: The JSON response object received from your backend containing the necessary data to initiate the WebAuthn authentication on the client device.
     - Parameter completion: A closure called asynchronously upon completion (success or failure) of the WebAuthn signing attempt.
     */
    public func signWebauthnTransaction(_ webAuthnAuthenticationData: TSWebAuthnAuthenticationData, options: TSAuthentication.WebAuthnAuthenticationOptions = [], completion: TSAuthenticationCompletion? = nil) {
        guard let controller else { completion?(.failure(.notInitialized)); return }
        
        controller.authenticate(webAuthnAuthenticationData, options: options)
    }
    
    /**
     Invokes a WebAuthn credential authentication, including prompting the user for biometrics, in order to verify a user's authorization for a specific action.
     If authentication is completed successfully, this function will return a callback containing a WebAuthnEncodedResult.
     The WebAuthnEncodedResult should be used to make a completion request using your backend API which will commuincate with Transmit's Service
     
     - Parameters:
        - username -  User identifier
        - approvalData - Additional data related to the action being approved. This should be a dictionary, where the keys and values contain only digits, alphabet, and the characters: -._
        - completion - The callback containing either error or completion result.
     */
    public func approvalWebAuthn(approvalData: [String: String], username: String? = nil, options: TSAuthentication.WebAuthnAuthenticationOptions = [], completion: TSApprovalCompletion? = nil) {
        guard let controller else { completion?(.failure(.notInitialized)); return }
        
        controller.approval(username: username, approvalData: approvalData, options: options, completion: completion)
    }
    
    /**
     Invokes a WebAuthn credential authentication, including prompting the user for biometrics, in order to verify a user's authorization for a specific action.
     If authentication is completed successfully, this function will return a callback containing a WebAuthnEncodedResult.
     The WebAuthnEncodedResult should be used to make a completion request using your backend API which will commuincate with Transmit's Service
     
     - Parameter webAuthnAuthenticationData: The JSON response object received from your backend containing the necessary data to initiate the WebAuthn approval on the client device.
     - Parameter completion: A closure that is called asynchronously upon the completion (success or failure) of the WebAuthn approval attempt.
     */
    public func approvalWebAuthn(_ webAuthnAuthenticationData: TSWebAuthnAuthenticationData, options: TSAuthentication.WebAuthnAuthenticationOptions = [], completion: TSApprovalCompletion? = nil) {
        guard let controller else { completion?(.failure(.notInitialized)); return }
        
        controller.approval(webAuthnAuthenticationData, options: options, completion: completion)
    }
    
    /**
     Registers native biometrics (Touch ID or Face ID) on the device for user authentication.
     */
    public func registerNativeBiometrics(username: String, completion: @escaping TSNativeBiometricsRegistrationCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        controller.registerNativeBiometrics(username: username, completion: completion)
    }
        
    /**
    Authenticates a user using native biometrics (Touch ID or Face ID).

    - Parameters:
      - username: User identifier.
      - challenge: The cryptographic challenge or payload to be signed.
      - completion: The callback containing either error or completion result.
    */
    public func authenticateNativeBiometrics(username: String, challenge: String, completion: @escaping TSNativeBiometricsAuthenticationCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        controller.authenticateNativeBiometrics(username: username, challenge: challenge, completion: completion)
    }
    
    /**
    Unregister native biometrics entry for a given user.
     - Parameters:
       - username: User identifier.
       - completion: The callback containing either error or completion result.
     */
    public func unregistersNativeBiometrics(username: String, completion: @escaping TSNativeBiometricsUnregisterCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        controller.unregisterNativeBiometrics(username: username, completion: completion)
    }
    
    /**
     Approves a user transaction using native biometrics (Touch ID or Face ID).
     - Parameters:
       - username: User identifier.
       - challenge: The cryptographic challenge or payload to be signed.
       - completion: The callback containing either error or completion result.
     */
    public func approvalNativeBiometrics(username: String, challenge: String, completion: @escaping TSNativeBiometricsApprovalCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        controller.approvalNativeBiometrics(username: username, challenge: challenge, completion: completion)
    }
    
    /**
    Registers a TOTP code generator.

    - Parameters:
      - URI: A TOTP URI string a standardized way to represent the parameters needed for TOTP authentication.
      - securityType: Specifies the method of protecting the stored TOTP secret.
      - completion: The callback containing either error or completion result.
    */
    public func registerTOTP(URI: String, securityType: TSTOTPSecurityType, completion: @escaping TSTOTPRegistrationCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        controller.registerTOTP(URI: URI, securityType: securityType, completion: completion)
    }
    
    /**
     Generates a Time-based One-Time Password (TOTP) code.

     - Parameters:
       - UUID: The unique identifier for which the registration data is stored.
       - completion: The callback containing either error or result object contaiting generated TOTP code.
    */
    public func generateTOTPCode(UUID: String, completion: @escaping TSTOTPGenerateCodeCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        controller.generateTOTPCode(UUID: UUID, completion: completion)
    }
    
    /**
     Generates a Time-based One-Time Password (TOTP) code.

     - Parameters:
       - UUID: The unique identifier for which the registration data is stored.
       - challenge: An additional value used to enhance security in the TOTP generation process.
       - completion: The callback containing either error or result object contaiting generated TOTP code.
    */
    public func generateTOTPCodeWithChallenge(UUID: String, challenge: String, completion: @escaping TSTOTPGenerateCodeCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        controller.generateTOTPCodeWithChallenge(UUID: UUID, challenge: challenge, completion: completion)
    }

    /**
     Retrieves device-specific information, such as public key and its associated ID, which are unique to the application installed on the device.
     */
    public func getDeviceInfo(_ completion: @escaping DeviceInfoCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        controller.getDeviceInfo(completion)
    }
    
    /**
     Signs the `challenge` string with the device key.
     - Parameter challenge: The string to sign.
     - Parameter completion: The callback containing either error or result object contaiting signed challenge.
     */
    public func signWithDeviceKey(challenge: String, completion: @escaping TSSignChallengeCompletion) {
        controller?.signChallenge(challenge, completion: completion)
    }
    
    /**
     Checks if the WebAuthn feature is supported on the current iOS version.
     @return
     `true` if passkeys are supported, `false` otherwise.
     */
    public static func isWebAuthnSupported() -> Bool {
        TSAuthenticationController.isWebAuthnSupported()
    }
    
    /**
     Checks if the user has enrolled biometric authentication (Touch ID or Face ID) on their device.
     @return
     `true` if biometric authentication is enrolled, `false` otherwise.
     */
    public static func isNativeBiometricsEnrolled() -> Bool {
        TSAuthenticationController.isNativeBiometricsEnrolled()
    }
}


private extension TSAuthentication {
    
    private struct PlistRoot: Codable {
        let credentials : Credentials
        let initOptions: TSAuthenticationInitOptions?
    }

    private struct Credentials: Codable {
        let baseUrl: String
        let clientId : String
        let domain : String?
    }

}

public extension TSAuthentication {
    
    /// Options for WebAuthn authentication.
    struct WebAuthnAuthenticationOptions: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        /// SDK will attempt to authenticate using a local passkey credentials stored on the device.
        public static let preferLocalCredantials = WebAuthnAuthenticationOptions(rawValue: 1 << 0)  // 0001
    }
}
