---
title: Changelog
toc:
  maxDepth: 2
---
# iOS Authentication SDK Changelog
	
## Authentication - 1.2.1 - May 2026
* feat: New security types for TOTP generation - 'devicePin' and 'devicePinOrBiometric'.
* feat: Added 'nativeBiometricsStatus()' API to retrieve the current native biometrics availability and status on the device.
* feat: Added 'nativeBiometricsType()' API to determine the currently available biometric authentication type (e.g., Face ID or Touch ID).
* feat: Enhanced iOS native biometrics error handling.

## Authentication - 1.2.0 - Feb 2026
* feat: Swift 6 support.

## Authentication - 1.1.17 - Dec 2025
* feat: Added compatibility with TSCoreSDK version 1.0.36.

## Authentication - 1.1.16 - Oct 2025
* feat: Add support PIN deletion.

## Authentication - 1.1.15 - May 2025
* feat: Add support PIN authentication.

## Authentication - 1.1.14 - Apr. 2025
* feat: Support elliptic-curve (EC) keys for mobile biometrics.
* feat: Allow multiple mobile-biometric registrations.

## Authentication - 1.1.13 - Apr. 2025
* feat: Add API for signing challenge using the device key.
* feat: Add APIs for client-side WebAuthn authentication, registration, and approval.
