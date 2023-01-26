# `TSAuthentication SDK iOS`

# Introduction

Add strong authentication with Passkeys to your native iOS application, while providing a native experience. This describes how to use our iOS SDK to register credentials and use them to authenticate for login and transaction approval scenarios. For transaction approval flows, transactions are signed per PSD2.0 SCA.

### How it works

Our WebAuthn iOS SDK implements Apple's [public-private key authentication](https://developer.apple.com/documentation/authenticationservices/public-private_key_authentication) for [passkeys](https://developer.apple.com/documentation/authenticationservices/public-private_key_authentication/supporting_passkeys). It allows you to add FIDO2-based biometric authentication to your iOS app, while providing your users a native experience instead of a browser-based one.
With passkeys, credentials are securely stored by the device in the iCloud keychain. These credentials must be associated with your domain, so they can be shared between your mobile app and your website (if you have one). Our SDK also cryptographically binds the credentials to the device itself, which ensures that they can only be used by the device that registered it.

### Benefits

The SDK offers many advantages over the APIs, including:

- Orchestration functionality to support decisions and complex flows
- Client-side WebAuthn calls, along with data processing before and after
- Stores local state, including registration status of devices, known users, etc.
- Simplifies all calls to the Transmit Service, reducing unnecessarily complexity
- Automatically handles tracking of cross-device flows, using simple event handlers


## Requirements

The requirements for passkey authentication include:

- iOS 15.0+ (or iOS 16.0+ for passkeys)
- Xcode 13.0+ (or Xcode 14.0+ for passkeys)
- Device with registered biometrics (e.g., FaceID or TouchID)
- Device registered with the user's Apple ID
- Device with iCloud KeyChain turned on


## Prerequisites

### Step 1: Configure your app

To integrate with Transmit, you'll need to configure an application.
From the [Applications](https://portal.identity.security/applications) page, [create a new application](https://developer.transmitsecurity.com/guides/user/create_new_application/) or use an existing one.
From the application settings:

- For Client type, select native
- For Redirect URI, enter your website URL. This is a mandatory field, but it isn't used for this flow. 
- Obtain your client ID and secret for API calls, which are auto-generated upon app creation.

### Step 2: Configure auth method

From the [Authentication](https://portal.identity.security/authentication/webAuthN) page, configure the WebAuthn login method for your application (whose name is shown at the top of the page in the drop-down list):

- For WebAuthn RP ID, add your website's full domain (e.g., www.example.com). This is the domain that will be associated with your credentials in Step 3.

- For WebAuthn RP Origin, use https://YOUR_DOMAIN, where YOUR_DOMAIN is your website's domain that you configured as the RP ID (e.g., https://www.example.com). This is the origin that will be provided when requesting registration and authentication with passkey credentials.

### Step 3: Associate your domain

In order to support passkeys, Apple requires having a domain associated with the relevant credential type (as noted [here](https://developer.apple.com/documentation/authenticationservices/public-private_key_authentication/supporting_passkeys)). This is done by adding the associated domain file to your website, and the appropriate entitlement in your app.

To use Apple's sample code project, follow [these](https://developer.apple.com/documentation/authenticationservices/connecting_to_a_service_with_passkeys) steps. The domain should be set to your domain, and match the WebAuthn RP ID configured in Step 2. To learn more about associated domains, click [here](https://developer.apple.com/documentation/xcode/supporting-associated-domains).


## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate TSAuthenticationSDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'TSAuthenticationSDK', '~> 1.0.0'
```

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is in early development, but TSAuthenticationSDK does support its use on supported platforms.

Once you have your Swift package set up, adding TSAuthenticationSDK as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/TransmitSecurity/authentication-ios-sdk", .upToNextMajor(from: "1.0.0"))
]
```

### Manually

If you prefer not to use any of the aforementioned dependency managers, you can integrate TSAuthenticationSDK into your project manually.

#### Embedded Framework

- Download the TSAuthenticationSDK framework manullay, open the new `TSAuthenticationSDK` folder, and drag the `TSAuthenticationSDK.xcframework` into the Project Frameworks directory of your application's Xcode project.

- And that's it!

  > The `TSAuthenticationSDK.framework` is automagically added as a target dependency, linked framework and embedded framework in a copy files build phase which is all you need to build on the simulator and a device.


## Usage

### Initialize the SDK:

```swift

let config = TSConfiguration()
    config.domain = "YOUR_DOMAIN"
    TSAuthentication.shared.initialize(serverUrl: "https://webauthn.identity.security/v1",
clientId: "CLIENT_ID", configuration: config) { response, error in
        if let error {
            print("SDK initialization failed \(String(describing: error.code))
\(String(describing: error.message))")
        } else {
            //Send the response.publicKey to the server
            print("SDK initialized")
        }
}

```

### Prepare registration:

```swift

TSAuthentication.shared.prepareWebauthnRegistration(username: "USERNAME", authSessionId:
"AUTH_SESSION_ID") { [weak self] success, error in
            if let error {
                //Handle error
            } else {
                //Complete the registration flow
} }

```

### Complete registration:

```swift

TSAuthentication.shared.executeWebauthnRegistration { [weak self] response, error in
    if let error {
       //Handle error
    } else {
       //User registered successfully. Use response.authCode for the token exchange
} }

```

### Prepare authentication:

```swift

TSAuthentication.shared.prepareWebauthnAuthentication(username: "USERNAME") { [weak
self] success, error in
        if let error {
            //Handle error
        } else {
            //Complete the authentication flow
} }

```

### Complete authentication:

```swift

TSAuthentication.shared.executeWebauthnAuthentication { [weak self] response, error in
    if let error {
        //Handle error
    } else {
       //User is authenticated. Use response.authCode for the token exchange
} }

```

### Prepare transaction signing:

```swift

let approvalData = [ "payee": "Acme", "payment_method": "Acme card", "pay_amount"
: "200"]
    TSAuthentication.shared.prepareWebauthnSignTransaction(username: "USERNAME",
approvalData: approvalData) { [weak self] success, error in
            if let error {
               //Handle error
            } else {
              //Complete the transaction signing flow
} }

```

### Complete transaction signing:

```swift

   TSAuthentication.shared.executeWebauthnSignTransaction() { [weak self] response, error
in
            if let error {
               //Handle error
            } else {
             //User has authenticated successfully. You can use the response.authCode for
token exchange.
            }
}

```

## Author

Transmit Security, https://github.com/TransmitSecurity

## License

This project is licensed under the Apache 2.0 license. See the LICENSE file for more info.