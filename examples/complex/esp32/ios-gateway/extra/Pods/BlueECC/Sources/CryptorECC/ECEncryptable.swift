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

/// A protocol for encrypting an instance of some object to generate some encrypted data.
@available(macOS 10.13, iOS 11, watchOS 4.0, tvOS 11.0, *)
protocol ECEncryptable {
    /// Encrypt the object using ECIES and produce some encrypted `Data`.
    func encrypt(with: ECPublicKey) throws -> Data
}

/// Extensions for encrypting or signing a `String` by converting it to UTF8 Data, then using the appropriate algorithm determined by the key's curve with the provided `ECPrivateKey` or `ECPublicKey`.
@available(macOS 10.13, iOS 11, watchOS 4.0, tvOS 11.0, *)
extension String: ECEncryptable {
    
    /// UTF8 encode the String to Data and encrypt it using the `ECPublicKey`.
    /// This either uses the `SecKeyAlgorithm`: `eciesEncryptionStandardVariableIVX963SHA256AESGCM`,
    /// or the equivalent OpenSSL implementation.
    /// - Parameter ecPrivateKey: The elliptic curve private key.
    /// - Returns: The encrypted Data.
    /// - Throws: An ECError is the plaintext fails to be encrypted.
    public func encrypt(with key: ECPublicKey) throws -> Data {
        return try Data(self.utf8).encrypt(with: key)
    }
}

/// Extension for signing `Data` with an `ECPrivateKey` and the algorithm determined by the key's curve.
@available(macOS 10.13, iOS 11, watchOS 4.0, tvOS 11.0, *)
extension Data: ECEncryptable {
    
    /// Encrypt the data using the `ECPublicKey`.
    /// This either uses the `SecKeyAlgorithm`: `eciesEncryptionStandardVariableIVX963SHA256AESGCM`,
    /// or the equivalent OpenSSL implementation.
    /// - Parameter ecPrivateKey: The elliptic curve private key.
    /// - Returns: The encrypted Data.
    /// - Throws: An ECError is the plaintext fails to be encrypted.
    public func encrypt(with key: ECPublicKey) throws -> Data {
    #if os(Linux)
        // Compute symmetric key
        let ec_key = EC_KEY_new_by_curve_name(key.curve.nativeCurve)
        defer {
            EC_KEY_free(ec_key)
        }
        EC_KEY_generate_key(ec_key)
        let ec_group = EC_KEY_get0_group(ec_key)
        let symKey_len = Int((EC_GROUP_get_degree(ec_group) + 7) / 8)
        let symKey = UnsafeMutablePointer<UInt8>.allocate(capacity: symKey_len)
        ECDH_compute_key(symKey, symKey_len, EC_KEY_get0_public_key(key.nativeKey), ec_key, nil)

        // get temp public key data
        let pub_bn_ctx = BN_CTX_new()
        BN_CTX_start(pub_bn_ctx)
        let pub = EC_KEY_get0_public_key(ec_key)
        let pub_bn = BN_new()
        EC_POINT_point2bn(ec_group, pub, POINT_CONVERSION_UNCOMPRESSED, pub_bn, pub_bn_ctx)
        let pubk = UnsafeMutablePointer<UInt8>.allocate(capacity: key.curve.keySize)
        BN_bn2bin(pub_bn, pubk)
        defer {
            BN_CTX_end(pub_bn_ctx)
            BN_CTX_free(pub_bn_ctx)
            BN_clear_free(pub_bn)
            #if swift(>=4.1)
            pubk.deallocate()
            symKey.deallocate()
            #else
            pubk.deallocate(capacity: key.curve.keySize)
            symKey.deallocate(capacity: symKey_len)
            #endif
        }
        
        // get aes key and iv using ANSI x9.63 Key Derivation Function
        let symKeyData = Data(bytes: symKey, count: symKey_len)
        let counterData = Data([0x00, 0x00, 0x00, 0x01])
        let sharedInfo = Data(bytes: pubk, count: key.curve.keySize)
        let preHashKey = symKeyData + counterData + sharedInfo
        let hashedKey = key.curve.digest(data: preHashKey)
        let aesKey = [UInt8](hashedKey.subdata(in: 0 ..< (hashedKey.count - 16)))
        let iv = [UInt8](hashedKey.subdata(in: (hashedKey.count - 16) ..< hashedKey.count))
        
        
        // AES encrypt data
        // Initialize encryption context
        let rsaEncryptCtx = EVP_CIPHER_CTX_new_wrapper()
        EVP_CIPHER_CTX_init_wrapper(rsaEncryptCtx)
        
        // Allocate encryption memory
        let tag = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        let encrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: self.count + 16)
        defer {
            // On completion deallocate the memory
            EVP_CIPHER_CTX_reset_wrapper(rsaEncryptCtx)
            EVP_CIPHER_CTX_free_wrapper(rsaEncryptCtx)
            
            #if swift(>=4.1)
            tag.deallocate()
            encrypted.deallocate()
            #else
            tag.deallocate(capacity: 16)
            encrypted.deallocate(capacity: self.count + 16)
            #endif
        }
        
        var processedLength: Int32 = 0
        var encLength: Int32 = 0
        guard EVP_EncryptInit_ex(rsaEncryptCtx, EVP_aes_128_gcm(), nil, nil, nil) == 1 else {
            throw ECError.failedEvpInit
        }
        // Set the IV length to be 16 to match Apple.
        guard EVP_CIPHER_CTX_ctrl(rsaEncryptCtx, EVP_CTRL_GCM_SET_IVLEN, 16, nil) == 1
            // Add the aad to the encryption context.
            // This is used in generating the GCM tag. We don't use this processedLength.
        else {
            throw ECError.failedEncryptionAlgorithm
        }
        guard EVP_EncryptInit_ex(rsaEncryptCtx, nil, nil, aesKey, iv) == 1 else {
            throw ECError.failedDecryptionAlgorithm
        }
        // Encrypt the plaintext into encrypted using gcmAlgorithm with the random aes key and all 0 iv.
        guard(self.withUnsafeBytes({ (plaintext: UnsafeRawBufferPointer) -> Int32 in
            return EVP_EncryptUpdate(rsaEncryptCtx, encrypted, &processedLength, plaintext.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(self.count))
        })) == 1 else {
            throw ECError.failedEncryptionAlgorithm
        }

        encLength += processedLength
        // Finalize the encryption so no more data will be added and generate the GCM tag.
        guard EVP_EncryptFinal_ex(rsaEncryptCtx, encrypted.advanced(by: Int(encLength)), &processedLength) == 1 else {
            throw ECError.failedEncryptionAlgorithm
        }

        encLength += processedLength
        // Get the 16 byte GCM tag.
        guard EVP_CIPHER_CTX_ctrl(rsaEncryptCtx, EVP_CTRL_GCM_GET_TAG, 16, tag) == 1 else {
            throw ECError.failedEncryptionAlgorithm
        }

        // Construct the envelope by combining the encrypted AES key, the encrypted date and the GCM tag.
        let ekFinal = Data(bytes: pubk, count: key.curve.keySize)
        let cipher = Data(bytes: encrypted, count: Int(encLength))
        let tagFinal = Data(bytes: tag, count: 16)
        return ekFinal + cipher + tagFinal
    #else
        var error: Unmanaged<CFError>? = nil
        guard let eData = SecKeyCreateEncryptedData(key.nativeKey,
                                                    key.curve.encryptionAlgorithm,
                                                    self as CFData,
                                                    &error)
        else {
            guard let error = error?.takeRetainedValue() else {
                throw ECError.failedEncryptionAlgorithm
            }
            throw error
        }
        
        return eData as Data
    #endif
    }
}
