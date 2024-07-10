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
    func initialize(baseUrl: String, clientId: String, domain: String?)
    
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
    public func initialize(baseUrl: String = "https://api.transmitsecurity.io/", clientId: String, domain: String? = nil) {
        guard controller == nil else { return }
        
        let controller = TSAuthenticationController()
        
        controller.initialize(baseUrl: baseUrl,
                              clientId: clientId,
                              domain: domain)
        
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
                                  domain: fileData.credentials.domain)
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
    
    /**
     Invokes a WebAuthn credential authentication, including prompting the user for biometrics, in order to verify a user's authorization for a specific action.
     If authentication is completed successfully, this function will return a callback containing a WebAuthnEncodedResult.
     The WebAuthnEncodedResult should be used to make a completion request using your backend API which will commuincate with Transmit's Service
     
     - Parameters:
        - username -  User identifier
        - approvalData - Additional data related to the action being approved. This should be a dictionary, where the keys and values contain only digits, alphabet, and the characters: -._
        - completion - The callback containing either error or completion result.
     */
    public func approvalWebAuthn(username: String, approvalData: [String: String], completion: TSApprovalCompletion? = nil) {
        guard let controller else { completion?(.failure(.notInitialized)); return }
        
        controller.approval(username: username, approvalData: approvalData, completion: completion)
    }
    
    /**
     Registers native biometrics (Touch ID or Face ID) on the device for user authentication.
     */
    public func registerNativeBiometrics(username: String, completion: @escaping TSNativeBiometricsRegistrationCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        Task {
            await controller.registerNativeBiometrics(username: username, completion: completion)
        }
    }
    
    /**
     Authenticates a user using native biometrics (Touch ID or Face ID).
     */
    public func authenticateNativeBiometrics(username: String, challenge: String, completion: @escaping TSNativeBiometricsAuthenticationCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        Task {
            await controller.authenticateNativeBiometrics(username: username, challenge: challenge, completion: completion)
        }
    }
    
    /**
    Unregister native biometrics entry for a given user
     */
    public func unregistersNativeBiometrics(username: String, completion: @escaping TSNativeBiometricsUnregisterCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        Task {
            await controller.unregisterNativeBiometrics(username: username, completion: completion)
        }
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
     Retrieves device-specific information, such as public key and its associated ID, which are unique to the application installed on the device.
     */
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
    }

    private struct Credentials: Codable {
        let baseUrl, clientId : String
        let domain : String?
    }

}
