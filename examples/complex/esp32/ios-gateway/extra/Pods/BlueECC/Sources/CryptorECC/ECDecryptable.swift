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

/// Extensions for encrypting, decrypting or signing `Data` using the appropriate algorithm determined by the key's curve with the provided `ECPrivateKey` or `ECPublicKey`.
@available(macOS 10.13, iOS 11, watchOS 4.0, tvOS 11.0, *)
extension Data {
    
    /// Decrypt the encrypted data using the provided `ECPrivateKey`.
    /// The signing algorithm used is determined based on the private key's elliptic curve.
    /// - Parameter ecPrivateKey: The elliptic curve private key.
    /// - Returns: The plaintext Data.
    /// - Throws: An ECError if the Encrypted data fails to be decrypted.
    public func decrypt(with key: ECPrivateKey) throws -> Data {
    #if os(Linux)
        // Initialize the decryption context.
        let rsaDecryptCtx = EVP_CIPHER_CTX_new()
        EVP_CIPHER_CTX_init_wrapper(rsaDecryptCtx)
        
        let tagLength = 16
        let encKeyLength = key.curve.keySize
        let encryptedDataLength = Int(self.count) - encKeyLength - tagLength
        // Extract encryptedAESKey, encryptedData, GCM tag from data
        let encryptedKey = self.subdata(in: 0..<encKeyLength)
        let encryptedData = self.subdata(in: encKeyLength..<encKeyLength+encryptedDataLength)
        var tagData = self.subdata(in: encKeyLength+encryptedDataLength..<self.count)
        // Allocate memory for decryption
        let ec_group = EC_KEY_get0_group(key.nativeKey)
        let skey_len = Int((EC_GROUP_get_degree(ec_group) + 7) / 8)
        let symKey = UnsafeMutablePointer<UInt8>.allocate(capacity: skey_len)
        let decrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(encryptedData.count + 16))
        defer {
            // On completion deallocate the memory
            EVP_CIPHER_CTX_reset_wrapper(rsaDecryptCtx)
            EVP_CIPHER_CTX_free_wrapper(rsaDecryptCtx)
            #if swift(>=4.1)
            symKey.deallocate()
            decrypted.deallocate()
            #else
            symKey.deallocate(capacity: skey_len)
            decrypted.deallocate(capacity: Int(encryptedData.count + 16))
            #endif
        }

        // Get public key point from key
        let pubk_point = EC_POINT_new(ec_group)
        defer {
            EC_POINT_free(pubk_point)
        }
        encryptedKey.withUnsafeBytes({ (pubk: UnsafeRawBufferPointer) in
            let pubk_bn = BN_bin2bn(pubk.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(encryptedKey.count), nil)
            let pubk_bn_ctx = BN_CTX_new()
            BN_CTX_start(pubk_bn_ctx)
            EC_POINT_bn2point(ec_group, pubk_bn, pubk_point, pubk_bn_ctx)
            BN_CTX_end(pubk_bn_ctx)
            BN_CTX_free(pubk_bn_ctx)
            BN_clear_free(pubk_bn)
        })

        // calculate symmetric key
        ECDH_compute_key(symKey, skey_len, pubk_point, key.nativeKey, nil)
        // processedLen is the number of bytes that each EVP_DecryptUpdate/EVP_DecryptFinal decrypts.
        // The sum of processedLen is the total size of the decrypted message (decMsgLen)
        var processedLen: Int32 = 0
        var decMsgLen: Int32 = 0
        
        // get aes key and iv using ANSI x9.63 Key Derivation Function
        let symKeyData = Data(bytes: symKey, count: skey_len)
        let counterData = Data([0x00, 0x00, 0x00, 0x01])
        let preHashKey = symKeyData + counterData + encryptedKey
        let hashedKey = key.curve.digest(data: preHashKey)
        let aesKey = [UInt8](hashedKey.subdata(in: 0 ..< 16))
        let iv = [UInt8](hashedKey.subdata(in: 16 ..< 32))
        
        // Set the IV length to be 16 bytes.
        // Set the envelope decryption algorithm as 128 bit AES-GCM.
        guard EVP_DecryptInit_ex(rsaDecryptCtx, EVP_aes_128_gcm(), nil, nil, nil) == 1 else {
            throw ECError.failedEvpInit
        }
        guard EVP_CIPHER_CTX_ctrl(rsaDecryptCtx, EVP_CTRL_GCM_SET_IVLEN, 16, nil) == 1,
        // Set the AES key to be 16 bytes.
        EVP_CIPHER_CTX_set_key_length(rsaDecryptCtx, 16) == 1
        else {
            throw ECError.failedDecryptionAlgorithm
        }
        
        // Set the envelope decryption context AES key and IV.
        guard EVP_DecryptInit_ex(rsaDecryptCtx, nil, nil, aesKey, iv) == 1 else {
            throw ECError.failedDecryptionAlgorithm
        }
        
        // Decrypt the encrypted data using the symmetric key.
        guard encryptedData.withUnsafeBytes({ (enc: UnsafeRawBufferPointer) -> Int32 in
            return EVP_DecryptUpdate(rsaDecryptCtx, decrypted, &processedLen, enc.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(encryptedData.count))
        }) != 0 else {
            throw ECError.failedDecryptionAlgorithm
        }
        decMsgLen += processedLen
        // Verify the provided GCM tag.
        guard tagData.withUnsafeMutableBytes({ (tag: UnsafeMutableRawBufferPointer) -> Int32 in
            return EVP_CIPHER_CTX_ctrl(rsaDecryptCtx, EVP_CTRL_GCM_SET_TAG, 16, tag.baseAddress)
        }) == 1
        else {
            throw ECError.failedDecryptionAlgorithm
        }
        guard EVP_DecryptFinal_ex(rsaDecryptCtx, decrypted.advanced(by: Int(decMsgLen)), &processedLen) == 1 else {
            throw ECError.failedDecryptionAlgorithm
        }
        decMsgLen += processedLen
        // return the decrypted plaintext.
        return Data(bytes: decrypted, count: Int(decMsgLen))
    #else
        var error: Unmanaged<CFError>? = nil
        guard let eData = SecKeyCreateDecryptedData(key.nativeKey,
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
