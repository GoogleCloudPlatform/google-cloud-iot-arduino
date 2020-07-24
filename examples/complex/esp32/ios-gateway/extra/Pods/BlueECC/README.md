<p align="center">
    <a href="http://kitura.io/">
        <img src="https://raw.githubusercontent.com/IBM-Swift/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>


<p align="center">
    <a href="https://ibm-swift.github.io/BlueECC/index.html">
    <img src="https://img.shields.io/badge/apidoc-BlueECC-1FBCE4.svg?style=flat" alt="APIDoc">
    </a>
    <a href="https://travis-ci.org/IBM-Swift/BlueECC">
    <img src="https://travis-ci.org/IBM-Swift/BlueECC.svg?branch=master" alt="Build Status - Master">
    </a>
    <img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
    <img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
    <img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
    <a href="http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg" alt="Slack Status">
    </a>
</p>

# BlueECC

A cross platform Swift implementation of Elliptic Curve Digital Signature Algorithm (ECDSA) and Elliptic Curve Integrated Encryption Scheme (ECIES). This allows you to sign, verify, encrypt and decrypt using elliptic curve keys.

## Swift version

The latest version of BlueECC requires **Swift 4.1** or later. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.

## Usage

#### Add dependencies

Add the `BlueECC` package to the dependencies within your application’s `Package.swift` file. Substitute `"x.x.x"` with the latest `BlueECC` [release](https://github.com/IBM-Swift/BlueECC/releases).

```swift
.package(url: "https://github.com/IBM-Swift/BlueECC.git", from: "x.x.x")
```

Add `CryptorECC` to your target's dependencies:

```swift
.target(name: "example", dependencies: ["CryptorECC"]),
```

#### Import package

```swift
import CryptorECC
```

### Getting Started

#### Elliptic curve private key

you can generate an ECPrivate key using BlueECC.

```swift
let p256PrivateKey = try ECPrivateKey.make(for: .prime256v1)
```

You can then view the key in it's PEM format as follows:

```swift
let privateKeyPEM = p256PrivateKey.pemString
```

The following curves are supported:
- prime256v1
- secp384r1
- secp521r1

Alternatively, you may generate private key using a third party provider:

- You can generate a `p-256` private key as a `.p8` file for Apple services from [https://developer.apple.com/account/ios/authkey](https://developer.apple.com/account/ios/authkey/). This will produce a key that should be formatted as follows:
```swift
let privateKey =
"""
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQglf7ztYnsaHX2yiHJ
meHFl5dg05y4a/hD7wwuB7hSRpmhRANCAASKRzmboLbG0NZ54B5PXxYSU7fvO8U7
PyniQCWG+Agc3bdcgKU0RKApWYuBJKrZqyqLB2tTlgdtwcWSB0AEzVI8
-----END PRIVATE KEY-----
"""
```

- You can use OpenSSL [Command Line Elliptic Curve Operations](https://wiki.openssl.org/index.php/Command_Line_Elliptic_Curve_Operations).  

The following commands generate private keys for the three supported curves as `.pem` files:
```
// p-256
$ openssl ecparam -name prime256v1 -genkey -noout -out key.pem
// p-384
$ openssl ecparam -name secp384r1 -genkey -noout -out key.pem
// p-521
$ openssl ecparam -name secp521r1 -genkey -noout -out key.pem
```
These keys will be formatted as follows:
```swift
let privateKey =
"""
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIJX+87WJ7Gh19sohyZnhxZeXYNOcuGv4Q+8MLge4UkaZoAoGCCqGSM49
AwEHoUQDQgAEikc5m6C2xtDWeeAeT18WElO37zvFOz8p4kAlhvgIHN23XIClNESg
KVmLgSSq2asqiwdrU5YHbcHFkgdABM1SPA==
-----END EC PRIVATE KEY-----
"""
```

The key string can then be used to initialize an `ECPrivateKey` instance:
```swift
let eccPrivateKey = try ECPrivateKey(key: privateKey)
```

####  Elliptic curve public  key

You can use OpenSSL to generate an elliptic curve public key `.pem` file from any of the above elliptic curve private key files:
```
$ openssl ec -in key.pem -pubout -out public.pem
```
This will produce a public key formatted as follows:
```swift
let publicKey =
"""
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEikc5m6C2xtDWeeAeT18WElO37zvF
Oz8p4kAlhvgIHN23XIClNESgKVmLgSSq2asqiwdrU5YHbcHFkgdABM1SPA==
-----END PUBLIC KEY-----
"""
```
These keys can then be used to initialize an `ECPrivateKey` instance:
```swift
let eccPublicKey = try ECPublicKey(key: publicKey)
```

Alternatively, you can extract the public key from your `ECPrivateKey`:

```swift
let eccPublicKey = try eccPrivateKey.extractPublicKey()
print(eccPublicKey.pemString)
```  

#### Signing String or Data

BlueECC extends `String` and `Data` so you can call sign directly on your plaintext using an EC private key. This creates an `ECSignature` containing the r and s signature values:

```swift
let message = "hello world"
let signature = try message.sign(with: eccPrivateKey)
```

#### Verifying the signature

Use the public key to verify the signature for the plaintext:
```swift
let verified = signature.verify(plaintext: message, using: eccPublicKey)
if verified {
    print("Signature is valid for provided plaintext")
}
```

#### Encrypting String or Data

Use the public key to encrypt your plaintext String or Data to encrypted Data or an encrypted Base64Encoded String:
```swift
let encryptedData = try "Hello World".encrypt(with: eccPublicKey)
print(encryptedData.base64EncodedString())
```

#### Decrypting to plaintext

Use the private key to decrypt the encrypted Data or Base64Encoded String to plaintext Data or UTF8 String:

```swift
let decryptedData = try encryptedData.decrypt(with: eccPrivateKey)
print(String(data: decryptedData, encoding: .utf8))
```

#### Encryption interoperability

Cross platform encryption and decryption is currently only supported with `prime256v1` curves. The `secp384r1` and `secp521r1` curves do not support Linux encryption with Apple platform decryption and vice versa.

If you would like to interoperate with this repo,
The following describes the encryption process:
- Generate an ephemeral EC key pair
- Use ECDH of your EC pair to generate a symmetric key
- Use SHA256 ANSI x9.63 Key Derivation Function with the ephemeral public key to generate a 32 byte key
- Use the first 16 bytes as an AES-GCM key
- Use the second 16 bytes as the initialization vector (IV)
- Use aes_128_gcm to encrypt the plaintext and generate a 16 byte GCM tag
- Send the ephemeral public key, encrypted data and GCM tag

This is equivalent to: `kSecKeyAlgorithmECIESEncryptionStandardVariableIVX963SHA256AESGCM` when using apple security.  

## API Documentation

For more information visit our [API reference](https://ibm-swift.github.io/BlueECC/index.html).

## Community
We love to talk server-side Swift, and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](https://github.com/IBM-Swift/BlueECC/blob/master/LICENSE.txt).
