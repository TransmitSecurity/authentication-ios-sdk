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
public typealias DeviceInfoCompletion = (Result<TSDeviceInfo, TSAuthenticationError>) -> Void
public typealias TSTOTPRegistrationCompletion = (Result<TSTOTPRegistrationResult, TSAuthenticationError>) -> ()
public typealias TSTOTPGenerateCodeCompletion = (Result<TSTOTPGenerateCodeResult, TSAuthenticationError>) -> ()


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
    
    private struct Constants {
        struct Plist {
            static let fileName = "TransmitSecurity"
        }
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
     Creates a new WebAuthn SDK instance with your client context.
     Credentials are configured from TransmitSecurity.plist file
     */
    public func initializeSDK() throws {
        guard controller == nil else { return }
        
        let controller = TSAuthenticationController()
        
        do {
            let fileData = try TSFile.readFromAppPlist(named: Constants.Plist.fileName, as: PlistRoot.self)
            var configuration : TSConfiguration? = nil
            if let domain = fileData.credentials.domain {
                configuration = TSConfiguration(domain: domain)
            }
            controller.initialize(baseUrl: fileData.credentials.baseUrl, clientId: fileData.credentials.clientId, configuration: configuration)
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
     Registers a user using the device's native biometric authentication system (e.g., Touch ID, Face ID).
     */
    public func registerNativeBiometrics(username: String, completion: @escaping TSNativeBiometricsRegistrationCompletion) {
        guard let controller else { completion(.failure(.notInitialized)); return }
        
        Task {
            await controller.registerNativeBiometrics(username: username, completion: completion)
        }
    }
    
    /**
     Authenticates a user using the device's native biometric authentication system (e.g., Touch ID, Face ID).
     */
    public func authenticateNativeBiometrics(username: String, challenge: String, completion: @escaping TSNativeBiometricsAuthenticationCompletion) {
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
