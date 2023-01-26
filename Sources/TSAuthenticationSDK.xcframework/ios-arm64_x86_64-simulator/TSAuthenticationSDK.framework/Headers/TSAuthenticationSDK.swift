//
//  TSAuthenticationSDK.swift
//  TSWebAuthnSdk
//
//  Created by Omar Ayed on 28/11/2022.
//

import UIKit


public typealias TSAuthenticationInitCompletion = ((TSAuthenticationInitResponse?, TSAuthenticationError?) -> ())?
public typealias TSAuthenticationCompletion = ((Bool, TSAuthenticationError?) -> ())?
public typealias TSAuthenticationResponseCompletion = ((TSAuthenticationResponse?, TSAuthenticationError?) -> ())?


public enum TSAuthenticationErrorCode : String, CaseIterable, Equatable, Hashable, Codable {
   case notInitialized
   case userNotFound
   case userMismatch
   case missingPrepareStep
   case registrationFailed
   case authenticationFailed
   case invalidAuthSession
   case internetConnection
   case invalidConfig
   case invalidSignTransactionData
    
   //PassKeys error codes
   case unknown
   case canceled
   case invalidResponse
   case notHandled
   case failed
   case notInteractive
}


final public class TSAuthenticationError: NSObject {

    /**
     Error code representing what happened
     */
    public internal (set) var code: TSAuthenticationErrorCode!

    /**
     Error description
     */
    public internal (set) var message: String!

    /**
     A URI identifying a human-readable web page containing information about the error, if available.
     */
    public internal (set) var errorUri: String?
}


public protocol TSAuthenticationResponse: Codable {

    /**
     Authorization code. This can be used to obtain
     the resulting ID Token and Access Token
     This value is typically sent to application backend where it is
     exchanged for the sensitive Access Token.
     */
    var authCode: String! {get}
}


public protocol TSAuthenticationInitResponse: Codable {

    /**
     A Crypto ublic key, Send it to the server for further using.
     */
    var publicKey: String! {get}
}


final public class TSConfiguration: NSObject {

    /**
     An Associated domain with the webcredentials service type when making a registration or assertion request; otherwise, the request returns an error. See Supporting associated domains for more information.
     (https://developer.apple.com/documentation/xcode/supporting-associated-domains)
     */
    public var domain: String!
}


protocol TSBaseAuthenticationSdkProtocol: TSWebAuthnSdkProtocol {
    func initialize(baseUrl: String, clientId: String, configuration: TSConfiguration?, completion: TSAuthenticationInitCompletion)
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
    public func initialize(baseUrl: String, clientId: String, configuration: TSConfiguration? = nil, completion: TSAuthenticationInitCompletion = nil) {
        TSAuthenticationImpl.shared.initialize(baseUrl: baseUrl, clientId: clientId, configuration: configuration, completion: completion)
    }
    
    
    /**
     Obtains the registration challenge from the Transmit Service, and stores the response locally to be used by `executeWebauthnRegistration`. This allows reducing latency when registration is requested. To provide the best experience, this should be called as soon as the username is known. If the registration does not occur in a cross device flow, a secure context should be established using an authentication session which is obtained from a backend API call to the Transmit Service.
     */
    public func prepareWebauthnRegistration(username: String, authSessionId: String, completion: TSAuthenticationCompletion) {
        TSAuthenticationImpl.shared.prepareWebauthnRegistration(username: username, authSessionId: authSessionId, completion: completion)
    }
    
    
    /**
     Invokes a WebAuthn credential registration, including prompting the user for biometrics. This must be called only after calling `prepareWebauthnRegistration to obtain the server challenge.

     If registration is completed successfully, this call will return a promise that resolves to an authorization code, which can be used to obtain user tokens. If it fails, an SdkRejection will be returned instead.
     */
    public func executeWebauthnRegistration(completion: TSAuthenticationResponseCompletion = nil) {
        TSAuthenticationImpl.shared.executeWebauthnRegistration(completion: completion)
    }
    
    
    /**
     Obtains the authentication challenge from the Transmit Service, and stores the response locally to be used by `executeWebauthnAuthentication`. This allows reducing latency when authentication is requested. To provide the best experience, this should be called as soon as possible.

     This call must be invoked for a registered user. It is invoked on the last user that logged in or registered, unless you specify a different user in the request (for example, when explicitly switching to a different user). If the target user is not registered or in case of any other failure, an error will be returned.
    */
    public func prepareWebauthnAuthentication(username: String, completion: TSAuthenticationCompletion = nil) {
        TSAuthenticationImpl.shared.prepareWebauthnAuthentication(username: username, completion: completion)
    }
    
    
    /**
     Invokes a WebAuthn authentication, including prompting the user for biometrics. This must be called only after calling `prepareWebauthnAuthentication` to obtain the server challenge.

     If authentication is completed successfully, this call will return a promise that resolves to an authorization code, which can be used to obtain user tokens. If it fails, an error will be returned instead.
     */
    public func executeWebauthnAuthentication(completion: TSAuthenticationResponseCompletion = nil) {
        TSAuthenticationImpl.shared.executeWebauthnAuthentication(completion: completion)
    }
    
    /**
     Obtains the sign transaction challenge from the Transmit Service, and stores the response locally to be used by `executeWebauthnSignTransaction`. This allows reducing latency when authentication is requested. To provide the best experience, this should be called as soon as possible.

     This call must be invoked for a registered user. It is invoked on the last user that logged in or registered, unless you specify a different user in the request (for example, when explicitly switching to a different user). If the target user is not registered or in case of any other failure, an error will be returned.
    */
    public func prepareWebauthnSignTransaction(username: String, approvalData: [String : String], completion: TSAuthenticationCompletion = nil) {
        TSAuthenticationImpl.shared.prepareWebauthnSignTransaction(username: username, approvalData: approvalData, completion: completion)
    }
    
    /**
     Invokes a WebAuthn sign transactiontication, including prompting the user for biometrics. This must be called only after calling `prepareWebauthnSignTransaction` to obtain the server challenge.

     If authentication is completed successfully, this call will return a promise that resolves to an authorization code, which can be used to obtain user tokens. If it fails, an error will be returned instead.
     */
    public func executeWebauthnSignTransaction(completion: TSAuthenticationResponseCompletion = nil) {
        TSAuthenticationImpl.shared.executeWebauthnSignTransaction(completion: completion)
    }
    
}
