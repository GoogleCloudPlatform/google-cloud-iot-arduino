<p align="center">
    <a href="https://www.kitura.io/packages.html#all">
    <img src="https://img.shields.io/badge/docs-kitura.io-1FBCE4.svg" alt="APIDoc">
    </a>
    <a href="https://travis-ci.org/IBM-Swift/BlueRSA">
    <img src="https://travis-ci.org/IBM-Swift/BlueRSA.svg?branch=master" alt="Build Status - Master">
    </a>
    <img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
    <img src="https://img.shields.io/badge/os-iOS-green.svg?style=flat" alt="iOS">
    <img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
    <img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
    <a href="http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg" alt="Slack Status">
    </a>
</p>

# BlueRSA

Swift cross-platform RSA wrapper library for RSA encryption and signing. Works on supported Apple platforms (using Security framework).  Linux (using OpenSSL) is working but is still somewhat of a work in progress.

## Contents

* CryptorRSA: Utility functions for RSA encryption and signing. Pure Swift

## Prerequisites

### Swift

* Swift Open Source `swift-4.0.0-RELEASE` toolchain (**Minimum REQUIRED for latest release**)
* Swift Open Source `swift-4.2-RELEASE` toolchain (**Recommended**)
* Swift toolchain included in *Xcode Version 10.0 (10A255) or higher*.

### macOS

* macOS 10.12.0 (*Sierra*) or higher
* Xcode Version 9.0 (9A325) or higher using the included toolchain (**Minimum REQUIRED for latest release**).
* Xcode Version 10.0 (10A255) or higher using the included toolchain (**Recommended**).

### iOS

* iOS 10.3 or higher
* Xcode Version 9.0 (9A325) or higher using the included toolchain (**Minimum REQUIRED for latest release**).
* Xcode Version 10.0 (10A255) or higher using the included toolchain (**Recommended**).

### Linux

* Ubuntu 16.04 (or 16.10 but only tested on 16.04) and 18.04.
* One of the Swift Open Source toolchain listed above.
* OpenSSL is provided by the distribution.  **Note:** 1.0.x, 1.1.x and later releases of OpenSSL are supported.
* The appropriate **libssl-dev** package is required to be installed when building.


## Build

To build CryptorRSA from the command line:

```
% cd <path-to-clone>
% swift build
```

## Testing

To run the supplied unit tests for **CryptorRSA** from the command line:

```
% cd <path-to-clone>
% swift build
% swift test

```

## Using CryptorRSA

### Including in your project

#### Swift Package Manager

To include BlueRSA into a Swift Package Manager package, add it to the `dependencies` attribute defined in your `Package.swift` file. You can select the version using the `majorVersion` and `minor` parameters. For example:
```
	dependencies: [
		.Package(url: "https://github.com/IBM-Swift/BlueRSA", majorVersion: <majorVersion>, minor: <minor>)
	]
```

#### Carthage

To include BlueRSA in a project using Carthage, add a line to your `Cartfile` with the GitHub organization and project names and version. For example:
```
	github "IBM-Swift/BlueRSA" ~> <majorVersion>.<minor>
```

### Before starting

The first you need to do is import the CryptorRSA framework.  This is done by the following:

```
import CryptorRSA
```

### Data Types

BlueRSA supports the following *major* data types:

* Key Handling
	- `CryptorRSA.PublicKey` - Represents an RSA Public Key.
	- `CryptorRSA.PrivateKey` - Represents an RSA Private Key.

* Data Handling
	- `CryptorRSA.EncryptedData` - Represents encrypted data.
	- `CryptorRSA.PlaintextData` - Represents plaintext or decrypted data.
	- `CryptorRSA.SignedData` - Represents signed data.

### Key Handling

**BlueRSA** provides seven (7) functions each for creating public and private keys from data. They are as follows (where *createXXXX* is either `createPublicKey` or `createPrivateKey` depending on what you're trying to create):

- `CryptorRSA.createXXXX(with data: Data) throws` - This creates either a private or public key containing the data provided. *It is assumed that the data being provided is in the proper format.*
- `CryptorRSA.createXXXX(withBase64 base64String: String) throws` - This creates either a private or public key using the `Base64 encoded String` provided.
- `CryptorRSA.createXXXX(withPEM pemString: String) throws` - This creates either a private or public key using the `PEM encoded String` provided.
- `CryptorRSA.createXXXX(withPEMNamed pemName: String, onPath path: String) throws` - This creates either a private or public key using the `PEM encoded file` pointed at by the `pemName` and located on the path specified by `path` provided.
- `CryptorRSA.createXXXX(withDERNamed derName: String, onPath path: String) throws` - This creates either a private or public key using the `DER encoded file` pointed at by the `derName` and located on the path specified by `path` provided.
- `CryptorRSA.createXXXX(withPEMNamed pemName: String, in bundle: Bundle = Bundle.main) throws` - This creates either a private or public key using the `PEM encoded file` pointed at by the `pemName` and located in the `Bundle` specified by `bundle` provided. By default this API will look in the `main` bundle. **Note: Apple Platforms Only**
- `CryptorRSA.createXXXX(withDERNamed derName: String, in bundle: Bundle = Bundle.main) throws` - This creates either a private or public key using the `DER encoded file` pointed at by the `derName` and located in the `Bundle` specified by `bundle` provided. By default this API will look in the `main` bundle. **Note: Apple Platforms Only**

Additionally, there are three APIs for creating a *public key* by extracting the key from a PEM formatted certificate:  They are:

- `CryptorRSA.createPublicKey(extractingFrom data: Data) throws` - This creates either a public key by extracting from the `PEM encoded certificate` pointed at by the `data`.
- `CryptorRSA.createPublicKey(extractingFrom certName: String, onPath path: String) throws` - This creates a public key by extracting from the `PEM encoded certificate` pointed at by the `certName` and located on the path specified by `path` provided.
- `CryptorRSA.createPublicKey(extractingFrom certName: String, in bundle: Bundle = Bundle.main) throws` - This creates a public key using the `PEM encoded certificate` pointed at by the `derName` and located in the `Bundle` specified by `bundle` provided. By default this API will look in the `main` bundle. **Note: Apple Platforms Only**


**Example**

The following example illustrates creating a public key given PEM encoded file located on a certain path. *Note: Exception handling omitted for brevity.

```
import Foundation
import CryptorRSA

...

let keyName = ...
let keyPath = ...

let publicKey = try CryptorRSA.createPublicKey(withPEMNamed: keyName, onPath: keyPath)

...

<Do something with the key...>

```

### Data Encryption and Decryption Handling

**BlueRSA** provides functions for the creation of each of the three (3) data handling types:

**Plaintext Data Handling and Signing**

There are two class level functions for creating a `PlaintextData` object. These are:

- `CryptorRSA.createPlaintext(with data: Data) -> PlaintextData` - This function creates a `PlaintextData` containing the specified `data`.
- `CryptorRSA.createPlaintext(with string: String, using encoding: String.Encoding) throws -> PlaintextData` - This function creates a `PlaintextData` object using the `string` encoded with the specified `encoding` as the data.

Once the `PlaintextData` object is created, there are two instance functions that can be used to manipulate the contained data.  These are:

- `encrypted(with key: PublicKey, algorithm: Data.Algorithm) throws -> EncryptedData?` - This function allows you to encrypt containing data using the public `key` and `algorithm` specified.  This function returns an optional `EncryptedData` object containing the encryped data.
- `signed(with key: PrivateKey, algorithm: Data.Algorithm) throws -> SignedData?` - This function allows you to sign the contained data using the private `key` and `algorithm` specified.  This function returns an optional `SignedData` object containing the signature of the signed data.

**Example**

- *Encryption*: **Note:** Exception handling omitted for brevity.

```
import Foundation
import CryptorRSA

...

let keyName = ...
let keyPath = ...

let myData: Data = <... Data to be encrypted ...>

let publicKey = try CryptorRSA.createPublicKey(withPEMNamed: keyName, onPath: keyPath)
let myPlaintext = CryptorRSA.createPlaintext(with: myData)
let encryptedData = try myPlaintext.encrypt(with: publicKey, algorithm: .sha1)

...

< Do something with the encrypted data...>

```

- *Signing*: **Note:** Exception handling omitted for brevity.

```
import Foundation
import CryptorRSA

...

let keyName = ...
let keyPath = ...

let myData: Data = <... Data to be signed ...>

let privateKey = try CryptorRSA.createPrivateKey(withPEMNamed: keyName, onPath: keyPath)
let myPlaintext = CryptorRSA.createPlaintext(with: myData)
let signedData = try myPlaintext.signed(with: privateKey, algorithm: .sha1)

...

< Do something with the signed data...>

```
**Encrypted Data Handling**

There are two class level functions for creating a `EncryptedData` object. These are:

- `CryptorRSA.createEncrypted(with data: Data) -> EncryptedData` - This function creates a `EncryptedData` containing the specified encrypted `data`.
- `CryptorRSA.createEncrypted(with base64String: String) throws -> EncryptedData` - This function creates a `EncrpytedData` using the *Base64* representation of already encrypted data.

Once the `EncryptedData` object is created, there is an instance function that can be used to decrypt the enclosed data:

- `decrypted(with key: PrivateKey, algorithm: Data.Algorithm) throws -> DecryptedData?` - This function allows you to decrypt containing data using the public `key` and `algorithm` specified.  This function returns an optional `DecryptedData` object containing the encryped data.

BlueRSA currently supports `OAEP` padding, which is the recommended padding algorithm. 

**Example**

- *Decryption*: **Note**: Exception handling omitted for brevity.

```
import Foundation
import CryptorRSA

...

let keyName = ...
let keyPath = ...
let publicKey = try CryptorRSA.createPublicKey(withPEMNamed: keyName, onPath: keyPath)

let pkeyName = ...
let pkeyPath = ...
let privateKey = try CryptorRSA.createPrivateKey(withPEMNamed: pkeyName, onPath: pkeyPath)

let myData: Data = <... Data to be encrypted ...>

let myPlaintext = CryptorRSA.createPlaintext(with: myData)
let encryptedData = try myPlaintext.encrypt(with: publicKey, algorithm: .sha1)

let decryptedData = try encryptedData.decrypt(with: privateKey, algorithm: .sha1)

...

< Do something with the decrypted data...>


```


### Signature Verification Handling

There is a single class level function that can be used to create a `SignedData` object. It is:

- `CryptorRSA.createSigned(with data: Data) -> SignedData` - This function creates a `SignedData` containing the specified signed `data`.

Once created or obtained `PlaintextData` and `SignedData`, there is an instance function which can be used to verify the signature contained therein:

- `verify(with key: PublicKey, signature: SignedData, algorithm: Data.Algorithm) throws -> Bool` - This function is used to verify, using the public `key` and `algorithm`, the `signature`.  Returns true if the signature is valid, false otherwise.

- *Verifying*: **Note:** Exception handling omitted for brevity.

```
import Foundation
import CryptorRSA

...

let keyName = ...
let keyPath = ...
let publicKey = try CryptorRSA.createPublicKey(withPEMNamed: keyName, onPath: keyPath)

let pkeyName = ...
let pkeyPath = ...
let privateKey = try CryptorRSA.createPrivateKey(withPEMNamed: pkeyName, onPath: pkeyPath)

let myData: Data = <... Data to be signed ...>

let myPlaintext = CryptorRSA.createPlaintext(with: myData)
let signedData = try myPlaintext.signed(with: privateKey, algorithm: .sha1)

if try myPlaintext.verify(with: publicKey, signature: signedData, algorithm: .sha1) {

	print("Signature verified")

} else {

	print("Signature Verification Failed")
}

```

### Data Type Utility Functions

All three of the data handling types have two common utility instance functions.  These are:

- `digest(using algorithm: Data.Algorithm) throws -> Data` - This function returns a `Data` object containing a digest constructed using the specified `algorithm`.
- `string(using encoding: String.Encoding) throws -> String` - This functions returns a `String` representation of the data using the specified `encoding`.

## Community

We love to talk server-side Swift and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License

This library is licensed under Apache 2.0. Full license text is available in [LICENSE](https://github.com/IBM-Swift/BlueRSA/blob/master/LICENSE).
