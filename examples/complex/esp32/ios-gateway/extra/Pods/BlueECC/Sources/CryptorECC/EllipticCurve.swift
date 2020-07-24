//  Copyright © 2019 IBM. All rights reserved.
//
//     Licensed under the Apache License, Version 2.0 (the "License");
//     you may not use this file except in compliance with the License.
//     You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//     Unless required by applicable law or agreed to in writing, software
//     distributed under the License is distributed on an "AS IS" BASIS,
//     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//     See the License for the specific language governing permissions and
//     limitations under the License.
//

import Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    import CommonCrypto
#elseif os(Linux)
    import OpenSSL
#endif

/// An extensible list of elliptic curves supported by this repository.
@available(macOS 10.13, iOS 11, watchOS 4.0, tvOS 11.0, *)
public struct EllipticCurve: Equatable, CustomStringConvertible {
    
    private let internalRepresentation: InternalRepresentation
    
    // enum for faster comparisons
    private enum InternalRepresentation: String {
        case prime256v1, secp384r1, secp521r1
    }
    
    /// A prime256v1 curve.
    public static let prime256v1 = EllipticCurve.p256
    
    /// A secp384r1 curve.
    public static let secp384r1 = EllipticCurve.p384
    
    /// A secp521r1 curve.
    public static let secp521r1 = EllipticCurve.p521
    
    /// Checks if two Curves are equal, required for Equatable protocol.
    public static func == (lhs: EllipticCurve, rhs: EllipticCurve) -> Bool {
        return lhs.internalRepresentation == rhs.internalRepresentation
    }
    
    /// A String description of the Curve. Required for CustomStringConvertible protocol.
    public var description: String {
        return internalRepresentation.rawValue
    }
    
    #if os(Linux)
    typealias CC_LONG = size_t
    let signingAlgorithm: OpaquePointer?
    let nativeCurve: Int32
    let hashEngine = SHA256
    let hashLength = CC_LONG(SHA256_DIGEST_LENGTH)
    #else
    let signingAlgorithm: SecKeyAlgorithm
    let encryptionAlgorithm = SecKeyAlgorithm.eciesEncryptionStandardVariableIVX963SHA256AESGCM
    let hashEngine: (_ data: UnsafeRawPointer?, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>?
    let hashLength: CC_LONG
    #endif
    let keySize: Int
    
    #if os(Linux)
    /// Secure Hash Algorithm 2 256-bit
    static let p256 = EllipticCurve(internalRepresentation: .prime256v1,
                                    signingAlgorithm: .init(EVP_sha256()),
                                    nativeCurve: NID_X9_62_prime256v1,
                                    keySize: 65)
    
    /// Secure Hash Algorithm 2 384-bit
    static let p384 = EllipticCurve(internalRepresentation: .secp384r1,
                                    signingAlgorithm: .init(EVP_sha384()),
                                    nativeCurve: NID_secp384r1,
                                    keySize: 97)
    
    /// Secure Hash Algorithm 512-bit
    static let p521 = EllipticCurve(internalRepresentation: .secp521r1,
                                    signingAlgorithm: .init(EVP_sha512()),
                                    nativeCurve: NID_secp521r1,
                                    keySize: 133)
    #else
    /// Secure Hash Algorithm 2 256-bit
    static let p256 = EllipticCurve(internalRepresentation: .prime256v1,
                                    signingAlgorithm: .ecdsaSignatureDigestX962SHA256,
                                    hashEngine: CC_SHA256,
                                    hashLength: CC_LONG(CC_SHA256_DIGEST_LENGTH),
                                    keySize: 65)
    
    /// Secure Hash Algorithm 2 384-bit
    static let p384 = EllipticCurve(internalRepresentation: .secp384r1,
                                    signingAlgorithm: .ecdsaSignatureDigestX962SHA384,
                                    hashEngine: CC_SHA384,
                                    hashLength: CC_LONG(CC_SHA384_DIGEST_LENGTH),
                                    keySize: 97)
    
    /// Secure Hash Algorithm 512-bit
    static let p521 = EllipticCurve(internalRepresentation: .secp521r1,
                                    signingAlgorithm: .ecdsaSignatureDigestX962SHA512,
                                    hashEngine: CC_SHA512,
                                    hashLength: CC_LONG(CC_SHA512_DIGEST_LENGTH),
                                    keySize: 133)
    #endif
    
    // Select the ECAlgorithm based on the object identifier (OID) extracted from the EC key.
    static func objectToCurve(ObjectIdentifier: Data) throws -> EllipticCurve {
        
        if [UInt8](ObjectIdentifier) == [0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07] {
            // p-256 (e.g: prime256v1, secp256r1) private key
            return .prime256v1
        } else if [UInt8](ObjectIdentifier) == [0x2B, 0x81, 0x04, 0x00, 0x22] {
            // p-384 (e.g: secp384r1) private key
            return .secp384r1
        } else if [UInt8](ObjectIdentifier) == [0x2B, 0x81, 0x04, 0x00, 0x23] {
            // p-521 (e.g: secp521r1) private key
            return .secp521r1
        } else {
            throw ECError.unsupportedCurve
        }
    }
    
    /// Return a digest of the data based on the hashEngine.
    func digest(data: Data) -> Data {
        
        var hash = [UInt8](repeating: 0, count: Int(self.hashLength))
        data.withUnsafeBytes { ptr in
            guard let baseAddress = ptr.baseAddress else { return }
            _ = self.hashEngine(baseAddress.assumingMemoryBound(to: UInt8.self), CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}

extension String {
    
    ///
    /// Split a string to a specified length.
    ///
    ///    - Parameters:
    ///        - length:                Length of each split string.
    ///
    ///    - Returns:                    `[String]` containing each string.
    ///
    func split(to length: Int) -> [String] {
        
        var result = [String]()
        var collectedCharacters = [Character]()
        collectedCharacters.reserveCapacity(length)
        var count = 0
        
        for character in self {
            collectedCharacters.append(character)
            count += 1
            if count == length {
                // Reached the desired length
                count = 0
                result.append(String(collectedCharacters))
                collectedCharacters.removeAll(keepingCapacity: true)
            }
        }
        
        // Append the remainder
        if !collectedCharacters.isEmpty {
            result.append(String(collectedCharacters))
        }
        return result
    }
}
