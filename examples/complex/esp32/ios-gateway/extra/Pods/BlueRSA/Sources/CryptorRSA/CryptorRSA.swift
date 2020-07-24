//
//  CryptorRSA.swift
//  CryptorRSA
//
//  Created by Bill Abt on 1/17/17.
//
//  Copyright © 2017 IBM. All rights reserved.
//
// 	Licensed under the Apache License, Version 2.0 (the "License");
// 	you may not use this file except in compliance with the License.
// 	You may obtain a copy of the License at
//
// 	http://www.apache.org/licenses/LICENSE-2.0
//
// 	Unless required by applicable law or agreed to in writing, software
// 	distributed under the License is distributed on an "AS IS" BASIS,
// 	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// 	See the License for the specific language governing permissions and
// 	limitations under the License.
//

import Foundation

#if os(Linux)
    import OpenSSL
#endif

// MARK: -

// MARK: -

///
/// RSA Encryption/Decryption, Signing/Verification
///
@available(macOS 10.12, iOS 10.3, watchOS 3.3, tvOS 12.0, *)
public class CryptorRSA {
	
	// MARK: Class Functions
	
	///
	/// Create a plaintext data container.
	///
	/// - Parameters:
	///		- data:				`Data` containing the key data.
	///
	/// - Returns:				Newly initialized `PlaintextData`.
	///
	public class func createPlaintext(with data: Data) -> PlaintextData {
		
		return PlaintextData(with: data)
	}

	///
	/// Creates a message from a plaintext string, with the specified encoding.
	///
	/// - Parameters:
	///   - string: 			String value of the plaintext message
	///   - encoding: 			Encoding to use to generate the clear data
	///
	/// - Returns:				Newly initialized `PlaintextData`.
	///
	public class func createPlaintext(with string: String, using encoding: String.Encoding) throws -> PlaintextData {
		
		return try PlaintextData(with: string, using: encoding)
	}
	
	///
	/// Create an encrypted data container.
	///
	/// - Parameters:
	///		- data:				`Data` containing the encrypted data.
	///
	/// - Returns:				Newly initialized `EncryptedData`.
	///
	public class func createEncrypted(with data: Data) -> EncryptedData {
		
		return EncryptedData(with: data)
	}
	
	///
	/// Creates a message with a encrypted base64-encoded string.
	///
	/// - Parameters:
	///		- base64String: 	Base64-encoded data of an encrypted message
	///
	/// - Returns:				Newly initialized `EncryptedData`.
	///
	public class func createEncrypted(with base64String: String) throws -> EncryptedData {
		
		return try EncryptedData(withBase64: base64String)
	}
	
	///
	/// Create an signed data container.
	///
	/// - Parameters:
	///		- data:				`Data` containing the signed data.
	///
	/// - Returns:				Newly initialized `SignedData`.
	///
	public class func createSigned(with data: Data) -> SignedData {
		
		return SignedData(with: data)
	}
	
	///
	/// RSA Data Object: Allows for RSA Encryption/Decryption, Signing/Verification and various utility functions.
	///
	public class RSAData {
		
		// MARK: Enums
		
		/// Denotes the type of data this represents.
		public enum DataType {
			
			/// Plaintext
			case plaintextType
			
			/// Encrypted
			case encryptedType
			
			/// Signed
			case signedType
		}
		
		// MARK: -- Properties
		
		/// Data of the message
		public let data: Data
		
		/// Represents the type of data contained.
		public internal(set) var type: DataType = .plaintextType
		
		/// Base64-encoded string of the message data
		public var base64String: String {
			
			return data.base64EncodedString()
		}

		// MARK: -- Initializers
		
		///
		/// Initialize a new RSAData object.
		///
		/// - Parameters:
		///		- data:				`Data` containing the data.
		///		- type:				Type of data contained.
		///
		/// - Returns:				Newly initialized `RSAData`.
		///
		internal init(with data: Data, type: DataType) {
			
			self.data = data
			self.type = type
		}
		
		///
		/// Creates a RSAData with a encrypted base64-encoded string.
		///
		/// - Parameters:
	 	///		- base64String: 	Base64-encoded data of an encrypted message
		///
		/// - Returns:				Newly initialized `RSAData`.
		///
		internal init(withBase64 base64String: String) throws {
			
			guard let data = Data(base64Encoded: base64String) else {
				
				throw Error(code: CryptorRSA.ERR_BASE64_PEM_DATA, reason: "Couldn't convert base 64 encoded string ")
			}
			
			self.data = data
			self.type = .encryptedType
		}
		
		///
		/// Creates a message from a plaintext string, with the specified encoding.
		///
		/// - Parameters:
		///   - string: 			String value of the plaintext message
		///   - encoding: 			Encoding to use to generate the clear data
		///
		/// - Returns:				Newly initialized `RSAData`.
		///
		internal init(with string: String, using encoding: String.Encoding) throws {
			
			guard let data = string.data(using: encoding) else {
				
				throw Error(code: CryptorRSA.ERR_STRING_ENCODING, reason: "Couldn't convert string to data using specified encoding")
			}
			
			self.data = data
			self.type = .plaintextType
		}
		
		
		// MARK: -- Functions
		
		// MARK: --- Encrypt/Decrypt
		
		///
		/// Encrypt the data.
		///
		/// - Parameters:
		///		- key:				The `PublicKey`
		///		- algorithm:		The algorithm to use (`Data.Algorithm`).
		///
		///	- Returns:				A new optional `EncryptedData` containing the encrypted data.
		///
		public func encrypted(with key: PublicKey, algorithm: Data.Algorithm) throws -> EncryptedData? {
			
			// Must be plaintext...
			guard self.type == .plaintextType else {
				
				throw Error(code: CryptorRSA.ERR_NOT_PLAINTEXT, reason: "Data is not plaintext")
			}
			
			// Key must be public...
			guard key.type == .publicType else {
				
				throw Error(code: CryptorRSA.ERR_KEY_NOT_PUBLIC, reason: "Supplied key is not public")
			}
			
			#if os(Linux)
                switch algorithm {
                case .gcm:
                    return try encryptedGCM(with: key)
                case .sha1, .sha224, .sha256, .sha384, .sha512:
                    // Same algorithm is used regardless of sha
                    return try encryptedCBC(with: key)
                }
			#else
				
				var response: Unmanaged<CFError>? = nil
				let eData = SecKeyCreateEncryptedData(key.reference, algorithm.alogrithmForEncryption, self.data as CFData, &response)
				if response != nil {
				
					guard let error = response?.takeRetainedValue() else {
					
						throw Error(code: CryptorRSA.ERR_ENCRYPTION_FAILED, reason: "Encryption failed. Unable to determine error.")
					}
				
					throw Error(code: CryptorRSA.ERR_ENCRYPTION_FAILED, reason: "Encryption failed with error: \(error)")
				}
			
				return EncryptedData(with: eData! as Data)

			#endif
		}
		
		///
		/// Decrypt the data.
		///
		/// - Parameters:
		///		- key:				The `PrivateKey`
		///		- algorithm:		The algorithm to use (`Data.Algorithm`).
		///
		///	- Returns:				A new optional `PlaintextData` containing the decrypted data.
		///
		public func decrypted(with key: PrivateKey, algorithm: Data.Algorithm) throws -> PlaintextData? {
			
			// Must be encrypted...
			guard self.type == .encryptedType else {
				
				throw Error(code: CryptorRSA.ERR_NOT_ENCRYPTED, reason: "Data is plaintext")
			}
			
			// Key must be private...
			guard key.type == .privateType else {
				
				throw Error(code: CryptorRSA.ERR_KEY_NOT_PUBLIC, reason: "Supplied key is not private")
			}
			
			#if os(Linux)
				
                switch algorithm {
                case .gcm:
                    return try decryptedGCM(with: key)
                case .sha1, .sha224, .sha256, .sha384, .sha512:
                    // Same algorithm is used regardless of sha
                    return try decryptedCBC(with: key)
                }
                
			#else
				
				var response: Unmanaged<CFError>? = nil
				let pData = SecKeyCreateDecryptedData(key.reference, algorithm.alogrithmForEncryption, self.data as CFData, &response)
				if response != nil {
				
					guard let error = response?.takeRetainedValue() else {
					
						throw Error(code: CryptorRSA.ERR_DECRYPTION_FAILED, reason: "Decryption failed. Unable to determine error.")
					}
				
					throw Error(code: CryptorRSA.ERR_DECRYPTION_FAILED, reason: "Decryption failed with error: \(error)")
				}
				
				return PlaintextData(with: pData! as Data)
				
			#endif
		}
		
        #if os(Linux)
	        ///
    	    /// Encrypt the data using AES GCM SHA1 for cross platform support.
			///
			///	- Parameters:
			///		- key: 	Public key to use.
			///
			///	- Returns:	Encrypted data object.
			///
			func encryptedGCM(with key: PublicKey) throws -> EncryptedData? {
				// Initialize encryption context
				let rsaEncryptCtx = EVP_CIPHER_CTX_new_wrapper()
				EVP_CIPHER_CTX_init_wrapper(rsaEncryptCtx)
				defer {
					// On completion deallocate the memory
					EVP_CIPHER_CTX_reset_wrapper(rsaEncryptCtx)
					EVP_CIPHER_CTX_free_wrapper(rsaEncryptCtx)
				}
				// get rsaKey
				guard let rsaKey = EVP_PKEY_get1_RSA(.make(optional: key.reference)) else {
					let source = "Couldn't create key reference from key data"
					if let reason = CryptorRSA.getLastError(source: source) {
						throw Error(code: ERR_ADD_KEY, reason: reason)
					}
					throw Error(code: ERR_ADD_KEY, reason: source + ": No OpenSSL error reported.")
				}
				defer {
					RSA_free(rsaKey)
				}

				// Set the additional authenticated data (aad) as the RSA key modulus and publicExponent in an ASN1 sequence.
				guard let aad = key.publicKeyBytes else {
					let source = "Encryption failed"
					throw Error(code: ERR_ENCRYPTION_FAILED, reason: source + ": Failed to decode public key")
				}
				// if the RSA key is >= 4096 bits, use aes_256_gcm.
				let encryptedCapacity: Int
				let keySize: Int
				if aad.count > 525 {
					// Set the rsaEncryptCtx to use EVP_aes_256_gcm encryption.
					guard EVP_EncryptInit_ex(rsaEncryptCtx, EVP_aes_256_gcm(), nil, nil, nil) == 1 else {
						throw Error(code: ERR_ENCRYPTION_FAILED, reason: "Encryption failed: Failed to initialize encryption context")
					}
					encryptedCapacity = 512
					keySize = 32
				} else {
					// Set the rsaEncryptCtx to use EVP_aes_128_gcm encryption.
					guard EVP_EncryptInit_ex(rsaEncryptCtx, EVP_aes_128_gcm(), nil, nil, nil) == 1 else {
						throw Error(code: ERR_ENCRYPTION_FAILED, reason: "Encryption failed: Failed to initialize encryption context")
					}
					if aad.count > 300 {
						encryptedCapacity = 384
					} else if aad.count > 260 {
						encryptedCapacity = 256
					} else {
						encryptedCapacity = 128
					}
					keySize = 16
				}
				
				// Allocate encryption memory
				let aeskey = UnsafeMutablePointer<UInt8>.allocate(capacity: keySize)
				let encryptedKey = UnsafeMutablePointer<UInt8>.allocate(capacity: encryptedCapacity)
				let tag = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
				let encrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count + 16)
				defer {
					#if swift(>=4.1)
					aeskey.deallocate()
					encryptedKey.deallocate()
					tag.deallocate()
					encrypted.deallocate()
					#else
					aeskey.deallocate(capacity: keySize)
					encryptedKey.deallocate(capacity: encryptedCapacity)
					tag.deallocate(capacity: 16)
					encrypted.deallocate(capacity: data.count + 16)
					#endif
				}
				
				var processedLength: Int32 = 0
				var encLength: Int32 = 0
				// Apple use a 16 byte all 0 IV. This is allowed since a random key is generated for each encryption.
				let iv = [UInt8](repeating: 0, count: 16)
				
				// Set the IV length to be 16 to match Apple.
				guard EVP_CIPHER_CTX_ctrl(rsaEncryptCtx, EVP_CTRL_GCM_SET_IVLEN, 16, nil) == 1,
					// Generate 16/32 random bytes that will be used as the AES key.
					EVP_CIPHER_CTX_rand_key(rsaEncryptCtx, aeskey) == 1,
					// Set the aeskey and iv for the symmetric encryption.
					EVP_EncryptInit_ex(rsaEncryptCtx, nil, nil, aeskey, iv) == 1,
					// Encrypt the aes key using the rsa public key with SHA1, OAEP padding.
					RSA_public_encrypt(Int32(keySize), aeskey, encryptedKey, .make(optional: rsaKey), RSA_PKCS1_OAEP_PADDING) == encryptedCapacity,
					// Add the aad to the encryption context.
					// This is used in generating the GCM tag. We don't use this processedLength.
					EVP_EncryptUpdate(rsaEncryptCtx, nil, &processedLength, [UInt8](aad), Int32(aad.count)) == 1
					else {
						let source = "Encryption failed"
						if let reason = CryptorRSA.getLastError(source: source) {
							throw Error(code: ERR_ENCRYPTION_FAILED, reason: reason)
						}
						throw Error(code: ERR_ENCRYPTION_FAILED, reason: source + ": No OpenSSL error reported.")
				}
				
				// Encrypt the plaintext into encrypted using gcmAlgorithm with the random aes key and all 0 iv.
				guard(self.data.withUnsafeBytes({ (plaintext: UnsafeRawBufferPointer) -> Int32 in
					return EVP_EncryptUpdate(rsaEncryptCtx, encrypted, &processedLength, plaintext.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(data.count))
				})) == 1 else {
					let source = "Encryption failed"
					if let reason = CryptorRSA.getLastError(source: source) {
						throw Error(code: ERR_ENCRYPTION_FAILED, reason: reason)
					}
					throw Error(code: ERR_ENCRYPTION_FAILED, reason: source + ": No OpenSSL error reported.")
				}
				encLength += processedLength
				// Finalize the encryption so no more data will be added and generate the GCM tag.
				guard EVP_EncryptFinal_ex(rsaEncryptCtx, encrypted.advanced(by: Int(encLength)), &processedLength) == 1 else {
					let source = "Encryption failed"
					if let reason = CryptorRSA.getLastError(source: source) {
						throw Error(code: ERR_ENCRYPTION_FAILED, reason: reason)
					}
					throw Error(code: ERR_ENCRYPTION_FAILED, reason: source + ": No OpenSSL error reported.")
				}
				encLength += processedLength
				// Get the 16 byte GCM tag.
				guard EVP_CIPHER_CTX_ctrl(rsaEncryptCtx, EVP_CTRL_GCM_GET_TAG, 16, tag) == 1 else {
					let source = "Encryption failed"
					if let reason = CryptorRSA.getLastError(source: source) {
						throw Error(code: ERR_ENCRYPTION_FAILED, reason: reason)
					}
					throw Error(code: ERR_ENCRYPTION_FAILED, reason: source + ": No OpenSSL error reported.")
				}
				
				// Construct the envelope by combining the encrypted AES key, the encrypted date and the GCM tag.
				let ekFinal = Data(bytes: encryptedKey, count: encryptedCapacity)
				let cipher = Data(bytes: encrypted, count: Int(encLength))
				let tagFinal = Data(bytes: tag, count: 16)
				return EncryptedData(with: ekFinal + cipher + tagFinal)
			}
			
	        ///
    	    /// Encrypt the data using CBC for cross platform support.
			///
			///	- Parameters:
			///		- key: 	Public key to use.
			///
			///	- Returns:	Encrypted data object.
			///
			func encryptedCBC(with key: PublicKey) throws -> EncryptedData? {
				// Copy the EVP Key
				var evp_key = EVP_PKEY_new()
				let rsa = EVP_PKEY_get1_RSA(.make(optional: key.reference))
				EVP_PKEY_set1_RSA(evp_key, rsa)
				RSA_free(rsa)
				defer {
					EVP_PKEY_free(evp_key)
				}
				
				// TODO: hash type option is not being used right now.
				let enc = EVP_aes_256_cbc()
				let padding = RSA_PKCS1_OAEP_PADDING
				
				let rsaEncryptCtx = EVP_CIPHER_CTX_new_wrapper()
				
				defer {
					EVP_CIPHER_CTX_reset_wrapper(rsaEncryptCtx)
					EVP_CIPHER_CTX_free_wrapper(rsaEncryptCtx)
				}
				
				EVP_CIPHER_CTX_set_padding(rsaEncryptCtx, padding)
				
				// Initialize the AES encryption key array (of size 1)
				typealias UInt8Ptr = UnsafeMutablePointer<UInt8>?
				var ek: UInt8Ptr
				ek = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(EVP_PKEY_size(.make(optional: key.reference))))
				let ekPtr = UnsafeMutablePointer<UInt8Ptr>.allocate(capacity: MemoryLayout<UInt8Ptr>.size)
				ekPtr.pointee = ek
				
				// Assign size of the corresponding cipher's IV
				let IVLength = EVP_CIPHER_iv_length(.make(optional: enc))
				let iv = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(IVLength))
				let encrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: self.data.count + Int(IVLength))
				defer {
					#if swift(>=4.1)
						ek?.deallocate()
						ekPtr.deallocate()
						iv.deallocate()
						encrypted.deallocate()
					#else
						ek?.deallocate(capacity: Int(EVP_PKEY_size(.make(optional: key.reference))))
						ekPtr.deallocate(capacity: MemoryLayout<UInt8Ptr>.size)
						iv.deallocate(capacity: Int(IVLength))
						encrypted.deallocate(capacity: self.data.count + Int(IVLength))
					#endif
				}
				var encKeyLength: Int32 = 0
				var processedLength: Int32 = 0
				var encLength: Int32 = 0
				
				// Initializes a cipher context ctx for encryption with cipher type using a random secret key and IV.
				// The secret key is encrypted using the public key (evp_key can be an array of public keys)
				// Here we are using just 1 public key
				var status = EVP_SealInit(rsaEncryptCtx, .make(optional: enc), ekPtr, &encKeyLength, iv, &evp_key, 1)
				
				// SealInit should return the number of public keys that were input, here it is only 1
				guard status == 1 else {
					let source = "Encryption failed"
					if let reason = CryptorRSA.getLastError(source: source) {
						
						throw Error(code: ERR_ENCRYPTION_FAILED, reason: reason)
					}
					throw Error(code: ERR_ENCRYPTION_FAILED, reason: source + ": No OpenSSL error reported.")
				}
				
				// EVP_SealUpdate is a complex macros and therefore the compiler doesnt
				// convert it directly to swift. From /usr/local/opt/openssl/include/openssl/evp.h:
				_ = self.data.withUnsafeBytes({ (plaintext: UnsafeRawBufferPointer) -> Int32 in
					return EVP_EncryptUpdate(rsaEncryptCtx, encrypted, &processedLength, plaintext.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(self.data.count))
				})
				encLength = processedLength
				
				status = EVP_SealFinal(rsaEncryptCtx, encrypted.advanced(by: Int(encLength)), &processedLength)
				guard status == 1 else {
					let source = "Encryption failed"
					if let reason = CryptorRSA.getLastError(source: source) {
						
						throw Error(code: ERR_ENCRYPTION_FAILED, reason: reason)
					}
					throw Error(code: ERR_ENCRYPTION_FAILED, reason: source + ": No OpenSSL error reported.")
				}
				encLength += processedLength
				
				let cipher = Data(bytes: encrypted, count: Int(encLength))
				let ekFinal = Data(bytes: ek!, count: Int(encKeyLength))
				let ivFinal = Data(bytes: iv, count: Int(IVLength))
				
				return EncryptedData(with: ekFinal + cipher + ivFinal)
			}
				
			///
			/// Decrypt the data using AES GCM for cross platform support.
			///
			///	- Parameters:
			///		- key: 	Private key to use.
			///
			///	- Returns:	Decrypted data object.
			///
			func decryptedGCM(with key: PrivateKey) throws -> PlaintextData? {

				// Initialize the decryption context.
				let rsaDecryptCtx = EVP_CIPHER_CTX_new()
				EVP_CIPHER_CTX_init_wrapper(rsaDecryptCtx)
				defer {
					// On completion deallocate the memory
					EVP_CIPHER_CTX_reset_wrapper(rsaDecryptCtx)
					EVP_CIPHER_CTX_free_wrapper(rsaDecryptCtx)
				}
				// get rsaKey
				guard let rsaKey = EVP_PKEY_get1_RSA(.make(optional: key.reference)) else {
					let source = "Couldn't create key reference from key data"
					if let reason = CryptorRSA.getLastError(source: source) {
						throw Error(code: ERR_ADD_KEY, reason: reason)
					}
					throw Error(code: ERR_ADD_KEY, reason: source + ": No OpenSSL error reported.")
				}
				defer {
					RSA_free(rsaKey)
				}
				
				// Set the additional authenticated data (aad) as the RSA key modulus and publicExponent in an ASN1 sequence.
				guard let aad = key.publicKeyBytes else {
					let source = "Decryption failed"
					throw Error(code: ERR_DECRYPTION_FAILED, reason: source + ": Failed to decode public key")
				}
				// if the RSA key is larger than 4096 bits, use aes_256_gcm.
				let encKeyLength: Int
				let keySize: Int
				if aad.count > 525 {
					// Set the envelope decryption algorithm as 128 bit AES-GCM.
					guard EVP_DecryptInit_ex(rsaDecryptCtx, EVP_aes_256_gcm(), nil, nil, nil) == 1 else {
						throw Error(code: ERR_DECRYPTION_FAILED, reason: "Decryption failed: Failed to initialize decryption context")
					}
					encKeyLength = 512
					keySize = 32
				} else {
					// Set the envelope decryption algorithm as 128 bit AES-GCM.
					guard EVP_DecryptInit_ex(rsaDecryptCtx, EVP_aes_128_gcm(), nil, nil, nil) == 1 else {
						throw Error(code: ERR_DECRYPTION_FAILED, reason: "Decryption failed: Failed to initialize decryption context")
					}
					if aad.count > 300 {
						encKeyLength = 384
					} else if aad.count > 260 {
						encKeyLength = 256
					} else {
						encKeyLength = 128
					}
					keySize = 16
				}
				
				let tagLength = 16
				let encryptedDataLength = Int(data.count) - encKeyLength - tagLength
				
				// Extract encryptedAESKey, encryptedData, GCM tag from data
				let encryptedKey = data.subdata(in: 0..<encKeyLength)
				let encryptedData = data.subdata(in: encKeyLength..<encKeyLength+encryptedDataLength)
				var tagData = data.subdata(in: encKeyLength+encryptedDataLength..<data.count)
				// Allocate memory for decryption
				let aeskey = UnsafeMutablePointer<UInt8>.allocate(capacity: keySize)
				let decrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(encryptedData.count + 16))
				defer {
					// On completion deallocate the memory
					#if swift(>=4.1)
						aeskey.deallocate()
						decrypted.deallocate()
					#else
						aeskey.deallocate(capacity: keySize)
						decrypted.deallocate(capacity: Int(encryptedData.count + 16))
					#endif
				}
				// processedLen is the number of bytes that each EVP_DecryptUpdate/EVP_DecryptFinal decrypts.
				// The sum of processedLen is the total size of the decrypted message (decMsgLen)
				var processedLen: Int32 = 0
				var decMsgLen: Int32 = 0
				// Use a 16-byte all zero initialization vector (IV) to match Apple Security.
				let iv = [UInt8](repeating: 0, count: 16)

				// Decrypt the encryptedKey into the aeskey using the RSA private key
				guard RSA_private_decrypt(Int32(encryptedKey.count), [UInt8](encryptedKey), aeskey, rsaKey, RSA_PKCS1_OAEP_PADDING) != 0,
					// Set the IV length to be 16 bytes.
					EVP_CIPHER_CTX_ctrl(rsaDecryptCtx, EVP_CTRL_GCM_SET_IVLEN, 16, nil) == 1,
					// Set the AES key to be 16 bytes.
					EVP_CIPHER_CTX_set_key_length(rsaDecryptCtx, Int32(keySize)) == 1,
					// Set the envelope decryption context AES key and IV.
					EVP_DecryptInit_ex(rsaDecryptCtx, nil, nil, aeskey, iv) == 1,
					EVP_DecryptUpdate(rsaDecryptCtx, nil, &processedLen, [UInt8](aad), Int32(aad.count)) == 1
					else {
						let source = "Decryption failed"
						if let reason = CryptorRSA.getLastError(source: source) {
							
							throw Error(code: ERR_DECRYPTION_FAILED, reason: reason)
						}
						throw Error(code: ERR_DECRYPTION_FAILED, reason: source + ": No OpenSSL error reported.")
				}
				// Decrypt the encrypted data using the symmetric key.
				guard encryptedData.withUnsafeBytes({ (enc: UnsafeRawBufferPointer) -> Int32 in
					return EVP_DecryptUpdate(rsaDecryptCtx, decrypted, &processedLen, enc.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(encryptedData.count))
				}) != 0 else {
					let source = "Decryption failed"
					if let reason = CryptorRSA.getLastError(source: source) {
						throw Error(code: ERR_DECRYPTION_FAILED, reason: reason)
					}
					throw Error(code: ERR_DECRYPTION_FAILED, reason: source + ": No OpenSSL error reported.")
				}
				decMsgLen += processedLen
				
				// Verify the provided GCM tag.
				guard tagData.withUnsafeMutableBytes({ (tag: UnsafeMutableRawBufferPointer) -> Int32 in
					return EVP_CIPHER_CTX_ctrl(rsaDecryptCtx, EVP_CTRL_GCM_SET_TAG, 16, tag.baseAddress)
				}) == 1,
					EVP_DecryptFinal_ex(rsaDecryptCtx, decrypted.advanced(by: Int(decMsgLen)), &processedLen) == 1
					else {
						let source = "Decryption failed"
						if let reason = CryptorRSA.getLastError(source: source) {
							throw Error(code: ERR_DECRYPTION_FAILED, reason: reason)
						}
						throw Error(code: ERR_DECRYPTION_FAILED, reason: source + ": No OpenSSL error reported.")
				}
				decMsgLen += processedLen
				// return the decrypted plaintext.
				return PlaintextData(with: Data(bytes: decrypted, count: Int(decMsgLen)))
			}
			
			///
			/// Decrypt the data using CBC for cross platform support.
			///
			///	- Parameters:
			///		- key: 	Private key to use.
			///
			///	- Returns:	Decrypted data object.
			///
			func decryptedCBC(with key: PrivateKey) throws -> PlaintextData? {
				// Convert RSA key to EVP
				let encType = EVP_aes_256_cbc()
				let padding = RSA_PKCS1_OAEP_PADDING
				
				// Size of symmetric encryption
				let encKeyLength = Int(EVP_PKEY_size(.make(optional: key.reference)))
				// Size of the corresponding cipher's IV
				let encIVLength = Int(EVP_CIPHER_iv_length(.make(optional: encType)))
				// Size of encryptedKey
				let encryptedDataLength = Int(self.data.count) - encKeyLength - encIVLength

				// Extract encryptedKey, encryptedData, encryptedIV from data
				// self.data = encryptedKey + encryptedData + encryptedIV
				let encryptedKey = self.data.subdata(in: 0..<encKeyLength)
				let encryptedData = self.data.subdata(in: encKeyLength..<encKeyLength+encryptedDataLength)
				let encryptedIV = self.data.subdata(in: encKeyLength+encryptedDataLength..<self.data.count)
				
				let rsaDecryptCtx = EVP_CIPHER_CTX_new_wrapper()
				
				defer {
					EVP_CIPHER_CTX_reset_wrapper(rsaDecryptCtx)
					EVP_CIPHER_CTX_free_wrapper(rsaDecryptCtx)
				}
				
				EVP_CIPHER_CTX_set_padding(rsaDecryptCtx, padding)
				
				// processedLen is the number of bytes that each EVP_DecryptUpdate/EVP_DecryptFinal decrypts.
				// The sum of processedLen is the total size of the decrypted message (decMsgLen)
				var processedLen: Int32 = 0
				var decMsgLen: Int32 = 0
				
				let decrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(encryptedData.count + encryptedIV.count))
				defer {
					#if swift(>=4.1)
						decrypted.deallocate()
					#else
						decrypted.deallocate(capacity: Int(encryptedData.count + encryptedIV.count))
					#endif
				}
				// EVP_OpenInit returns 0 on error or the recovered secret key size if successful
				var status = encryptedKey.withUnsafeBytes({ (ek: UnsafeRawBufferPointer) -> Int32 in
					return encryptedIV.withUnsafeBytes({ (iv: UnsafeRawBufferPointer) -> Int32 in
						return EVP_OpenInit(rsaDecryptCtx, .make(optional: encType), ek.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(encryptedKey.count), iv.baseAddress?.assumingMemoryBound(to: UInt8.self), .make(optional: key.reference))
					})
				})
				guard status != 0 else {
					let source = "Decryption failed"
					if let reason = CryptorRSA.getLastError(source: source) {
						
						throw Error(code: ERR_DECRYPTION_FAILED, reason: reason)
					}
					throw Error(code: ERR_DECRYPTION_FAILED, reason: source + ": No OpenSSL error reported.")
				}
				
				// EVP_OpenUpdate is a complex macros and therefore the compiler doesnt
				// convert it directly to Swift. From /usr/local/opt/openssl/include/openssl/evp.h:
				_ = encryptedData.withUnsafeBytes({ (enc: UnsafeRawBufferPointer) -> Int32 in
					return EVP_DecryptUpdate(rsaDecryptCtx, decrypted, &processedLen, enc.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(encryptedData.count))
				})
				decMsgLen = processedLen
				
				status = EVP_OpenFinal(rsaDecryptCtx, decrypted.advanced(by: Int(decMsgLen)), &processedLen)
				guard status != 0 else {
					let source = "Decryption failed"
					if let reason = CryptorRSA.getLastError(source: source) {
						
						throw Error(code: ERR_DECRYPTION_FAILED, reason: reason)
					}
					throw Error(code: ERR_DECRYPTION_FAILED, reason: source + ": No OpenSSL error reported.")
				}
				decMsgLen += processedLen
				
				return PlaintextData(with: Data(bytes: decrypted, count: Int(decMsgLen)))
			}
			
        #endif
		
		// MARK: --- Sign/Verification
		
		///
		/// Sign the data
		///
		/// - Parameters:
		///		- key:				The `PrivateKey`.
		///		- algorithm:		The algorithm to use (`Data.Algorithm`).
		///		- usePSS: 			Bool stating whether or not to use RSA-PSS (Probabilistic signature scheme).
		///
		///	- Returns:				A new optional `SignedData` containing the digital signature.
		///
		public func signed(with key: PrivateKey, algorithm: Data.Algorithm, usePSS: Bool = false) throws -> SignedData? {
			
			// Must be plaintext...
			guard self.type == .plaintextType else {
				
				throw Error(code: CryptorRSA.ERR_NOT_PLAINTEXT, reason: "Data is not plaintext")
			}
			
			// Key must be private...
			guard key.type == .privateType else {
				
				throw Error(code: CryptorRSA.ERR_KEY_NOT_PRIVATE, reason: "Supplied key is not private")
			}
			
			#if os(Linux)
			
				let md_ctx = EVP_MD_CTX_new_wrapper()

                defer {
					EVP_MD_CTX_free_wrapper(md_ctx)
                }
                
                
                let (md, _) = algorithm.algorithmForSignature
                
				if usePSS {
					// If using PSS padding, create a PKEY and set it's padding, mask generation function and salt length.
					// NID_rsassaPss is `EVP_PKEY_RSA_PSS` as defined in evp.h
					var pkey_ctx = EVP_PKEY_CTX_new_id(NID_rsassaPss, nil)
					EVP_DigestSignInit(md_ctx, &pkey_ctx, .make(optional: md), nil, .make(optional: key.reference))
					EVP_PKEY_CTX_ctrl(pkey_ctx, EVP_PKEY_RSA, -1, EVP_PKEY_CTRL_RSA_PADDING, RSA_PKCS1_PSS_PADDING, nil)
					EVP_PKEY_CTX_ctrl(pkey_ctx, -1, EVP_PKEY_OP_SIGN, EVP_PKEY_CTRL_RSA_MGF1_MD, 0, .make(optional: md))
					// Sets salt length to be equal to message digest length
					EVP_PKEY_CTX_ctrl(pkey_ctx, -1, EVP_PKEY_OP_SIGN, EVP_PKEY_CTRL_RSA_PSS_SALTLEN, -1, .make(optional: md))
				} else {
					// Provide a pkey_ctx to EVP_DigestSignInit so that the EVP_PKEY_CTX of the signing operation
					// is written to it, to allow alternative signing options to be set
					EVP_DigestSignInit(md_ctx, nil, .make(optional: md), nil, .make(optional: key.reference))
				}
                
                // Convert Data to UnsafeRawPointer!
                _ = self.data.withUnsafeBytes({ (message: UnsafeRawBufferPointer) -> Int32 in
                    return EVP_DigestUpdate(md_ctx, message.baseAddress?.assumingMemoryBound(to: UInt8.self), self.data.count)
                })
                
                // Determine the size of the actual signature
                var sig_len: Int = 0
                EVP_DigestSignFinal(md_ctx, nil, &sig_len)
                let sig = UnsafeMutablePointer<UInt8>.allocate(capacity: sig_len)
                
                defer {
                    #if swift(>=4.1)
                    	sig.deallocate()
                    #else
                    	sig.deallocate(capacity: sig_len)
                    #endif
                }
            
                let rc = EVP_DigestSignFinal(md_ctx, sig, &sig_len)
                guard rc == 1, sig_len > 0 else {
                    let source = "Signing failed."
                    if let reason = CryptorRSA.getLastError(source: source) {
                        
                        throw Error(code: ERR_SIGNING_FAILED, reason: reason)
                    }
                    throw Error(code: ERR_SIGNING_FAILED, reason: source + ": No OpenSSL error reported.")
                }
                
                return SignedData(with: Data(bytes: sig, count: sig_len))

			#else
				
				let signingAlgorithm: SecKeyAlgorithm
				if usePSS {
					if #available(macOS 10.13, iOS 11.0, watchOS 4.0, *) {
						signingAlgorithm = usePSS ? algorithm.algorithmForPssSignature : algorithm.algorithmForSignature
					} else {
						throw Error(code: ERR_NOT_IMPLEMENTED, reason: "RSA-PSS only supported on macOS 10.13/iOS 10.0 and above.")
					}
				} else {
					signingAlgorithm = algorithm.algorithmForSignature
				}
			
				var response: Unmanaged<CFError>? = nil
				let sData = SecKeyCreateSignature(key.reference, signingAlgorithm, self.data as CFData, &response)
				if response != nil {
				
					guard let error = response?.takeRetainedValue() else {
					
						throw Error(code: CryptorRSA.ERR_SIGNING_FAILED, reason: "Signing failed. Unable to determine error.")
					}
				
					throw Error(code: CryptorRSA.ERR_SIGNING_FAILED, reason: "Signing failed with error: \(error)")
				}
				
				return SignedData(with: sData! as Data)
				
			#endif
		}
		
		///
		/// Verify the signature
		///
		/// - Parameters:
		///		- key:				The `PublicKey`.
		///		- signature:		The `SignedData` containing the signature to verify against.
		///		- algorithm:		The algorithm to use (`Data.Algorithm`).
		///		- usePSS: 			Bool stating whether or not to use RSA-PSS (Probabilistic signature scheme).
		///
		///	- Returns:				True if verification is successful, false otherwise
		///
		public func verify(with key: PublicKey, signature: SignedData, algorithm: Data.Algorithm, usePSS: Bool = false) throws -> Bool {
			
			// Must be plaintext...
			guard self.type == .plaintextType else {
				
				throw Error(code: CryptorRSA.ERR_NOT_PLAINTEXT, reason: "Data is not plaintext")
			}
			
			// Key must be public...
			guard key.type == .publicType else {
				
				throw Error(code: CryptorRSA.ERR_KEY_NOT_PRIVATE, reason: "Supplied key is not public")
			}
			// Signature must be signed data...
			guard signature.type == .signedType else {
				
				throw Error(code: CryptorRSA.ERR_NOT_SIGNED_DATA, reason: "Supplied signature is not of signed data type")
			}
			
			#if os(Linux)
				
				let md_ctx = EVP_MD_CTX_new_wrapper()

                defer {
					EVP_MD_CTX_free_wrapper(md_ctx)
                }


                let (md, _) = algorithm.algorithmForSignature
                
				if usePSS {
					// If using PSS padding, create a PKEY and set it's padding and mask generation function.
					var pkey_ctx = EVP_PKEY_CTX_new_id(NID_rsassaPss, nil)
					EVP_DigestVerifyInit(md_ctx, &pkey_ctx, .make(optional: md), nil, .make(optional: key.reference))
					EVP_PKEY_CTX_ctrl(pkey_ctx, EVP_PKEY_RSA, -1, EVP_PKEY_CTRL_RSA_PADDING, RSA_PKCS1_PSS_PADDING, nil)
					EVP_PKEY_CTX_ctrl(pkey_ctx, -1, EVP_PKEY_OP_VERIFY, EVP_PKEY_CTRL_RSA_MGF1_MD, 0, .make(optional: md))
				} else {
					// Provide a pkey_ctx to EVP_DigestSignInit so that the EVP_PKEY_CTX of the signing operation
					// is written to it, to allow alternative signing options to be set
					EVP_DigestVerifyInit(md_ctx, nil, .make(optional: md), nil, .make(optional: key.reference))
				}


                var rc = self.data.withUnsafeBytes({ (message: UnsafeRawBufferPointer) -> Int32 in
                    return EVP_DigestUpdate(md_ctx, message.baseAddress?.assumingMemoryBound(to: UInt8.self), self.data.count)
                })
                guard rc == 1 else {
                    let source = "Signature verification failed."
                    if let reason = CryptorRSA.getLastError(source: source) {
                        
                        throw Error(code: ERR_VERIFICATION_FAILED, reason: reason)
                    }
                    throw Error(code: ERR_VERIFICATION_FAILED, reason: source + ": No OpenSSL error reported.")
                }

                // Unlike other return values above, this return indicates if signature verifies or not
                rc = signature.data.withUnsafeBytes({ (sig: UnsafeRawBufferPointer) -> Int32 in
                    // Wrapper for OpenSSL EVP_DigestVerifyFinal function defined in
                    // IBM-Swift/OpenSSL/shim.h, to provide compatibility with OpenSSL
                    // 1.0.1 and 1.0.2 on Ubuntu 14.04 and 16.04, respectively.
                    return SSL_EVP_digestVerifyFinal_wrapper(md_ctx, sig.baseAddress?.assumingMemoryBound(to: UInt8.self), signature.data.count)
                })
                
                return (rc == 1) ? true : false
				
			#else
				
				let signingAlgorithm: SecKeyAlgorithm
				if usePSS {
					if #available(macOS 10.13, iOS 11.0, watchOS 4.0, *) {
						signingAlgorithm = usePSS ? algorithm.algorithmForPssSignature : algorithm.algorithmForSignature
					} else {
						throw Error(code: ERR_NOT_IMPLEMENTED, reason: "RSA-PSS only supported on macOS 10.13/iOS 10.0 and above.")
					}
				} else {
					signingAlgorithm = algorithm.algorithmForSignature
				}

				var response: Unmanaged<CFError>? = nil
				let result = SecKeyVerifySignature(key.reference, signingAlgorithm, self.data as CFData, signature.data as CFData, &response)
				if response != nil {
				
					guard let error = response?.takeRetainedValue() else {
					
						throw Error(code: CryptorRSA.ERR_VERIFICATION_FAILED, reason: "Signature verification failed. Unable to determine error.")
					}
				
					throw Error(code: CryptorRSA.ERR_VERIFICATION_FAILED, reason: "Signature verification failed with error: \(error)")
				}
			
				return result
			
			#endif
		}
		
		// MARK: --- Utility
		
		///
		/// Retrieve a digest of the data using the specified algorithm.
		///
		/// - Parameters:
		///		- algorithm:		Algoririthm to use.
 		///
		///	- Returns:				`Data` containing the digest.
		///
		public func digest(using algorithm: Data.Algorithm) throws -> Data {
			
			return try self.data.digest(using: algorithm)
		}
		
		///
		/// String representation of message in specified string encoding.
		///
		/// - Parameters:
	 	///		- encoding: 		Encoding to use during the string conversion
		///
		/// - Returns: 				String representation of the message
		///
		public func string(using encoding: String.Encoding) throws -> String {
			
			guard let str = String(data: data, encoding: encoding) else {
				
				throw Error(code: CryptorRSA.ERR_STRING_ENCODING, reason: "Couldn't convert data to string representation")
			}
			
			return str
		}
		
	}
	
	// MARK: -
	
	///
	/// Plaintext Data - Represents data not encrypted or signed.
	///
	public class PlaintextData: RSAData {
		
		// MARK: Initializers
		
		///
		/// Initialize a new PlaintextData object.
		///
		/// - Parameters:
		///		- data:				`Data` containing the data.
		///
		/// - Returns:				Newly initialized `PlaintextData`.
		///
		internal init(with data: Data) {

			super.init(with: data, type: .plaintextType)
		}
		
		///
		/// Creates a message from a plaintext string, with the specified encoding.
		///
		/// - Parameters:
		///   - string: 			String value of the plaintext message
		///   - encoding: 			Encoding to use to generate the clear data
		///
		/// - Returns:				Newly initialized `RSAData`.
		///
		internal override init(with string: String, using encoding: String.Encoding) throws {
		
			try super.init(with: string, using: encoding)
		}
	}
	
	// MARK: -
	
	///
	/// Encrypted Data - Represents data encrypted.
	///
	public class EncryptedData: RSAData {
		
		// MARK: Initializers
		
		///
		/// Initialize a new EncryptedData object.
		///
		/// - Parameters:
		///		- data:				`Data` containing the data.
		///
		/// - Returns:				Newly initialized EncryptedData`.
		///
		public init(with data: Data) {
			
			super.init(with: data, type: .encryptedType)
		}
		
		///
		/// Creates a RSAData with a encrypted base64-encoded string.
		///
		/// - Parameters:
		///		- base64String: 	Base64-encoded data of an encrypted message
		///
		/// - Returns:				Newly initialized `RSAData`.
		///
		public override init(withBase64 base64String: String) throws {
		
			try super.init(withBase64: base64String)
		}
	}
	
	// MARK: -
	
	///
	/// Signed Data - Represents data that is signed.
	///
	public class SignedData: RSAData {
		
		// MARK: -- Initializers
		
		///
		/// Initialize a new SignedData object.
		///
		/// - Parameters:
		///		- data:				`Data` containing the data.
		///
		/// - Returns:				Newly initialized `SignedData`.
		///
		public init(with data: Data) {
			
			super.init(with: data, type: .signedType)
		}
		
	}
	
}

