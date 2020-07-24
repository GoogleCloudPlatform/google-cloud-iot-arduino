//
//  CryptorRSADigest.swift
//  CryptorRSA
//
//  Created by Bill Abt on 1/18/17.
//
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

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	import CommonCrypto
#elseif os(Linux)
	import OpenSSL
	public typealias CC_LONG = size_t
#endif

import Foundation

// MARK: -- RSA Digest Extension for Data

///
/// Digest Handling Extension
///
extension Data {
	
	// MARK: Enums
	
	///
	/// Enumerates available Digest algorithms
	///
	public enum Algorithm {
		
		/// Secure Hash Algorithm 1
		case sha1
		
		/// Secure Hash Algorithm 2 224-bit
		case sha224
		
		/// Secure Hash Algorithm 2 256-bit
		case sha256
		
		/// Secure Hash Algorithm 2 384-bit
		case sha384
		
		/// Secure Hash Algorithm 2 512-bit
		case sha512
        
		/// Secure Hash Algorithm 1 using AES-GCM envelope encryption.
		/// use this algorithm for cross platform encryption/decryption.
		case gcm
        
		/// Digest Length
		public var length: CC_LONG {
			
			#if os(Linux)
				
				switch self {
					
				case .sha1:
					return CC_LONG(SHA_DIGEST_LENGTH)
					
				case .sha224:
					return CC_LONG(SHA224_DIGEST_LENGTH)
					
				case .sha256:
					return CC_LONG(SHA256_DIGEST_LENGTH)
					
				case .sha384:
					return CC_LONG(SHA384_DIGEST_LENGTH)
					
				case .sha512:
					return CC_LONG(SHA512_DIGEST_LENGTH)
					
                case .gcm:
                    return CC_LONG(SHA_DIGEST_LENGTH)
				}
				
			#else

				switch self {
				
				case .sha1:
					return CC_LONG(CC_SHA1_DIGEST_LENGTH)
					
				case .sha224:
					return CC_LONG(CC_SHA224_DIGEST_LENGTH)
					
				case .sha256:
					return CC_LONG(CC_SHA256_DIGEST_LENGTH)
					
				case .sha384:
					return CC_LONG(CC_SHA384_DIGEST_LENGTH)
					
				case .sha512:
					return CC_LONG(CC_SHA512_DIGEST_LENGTH)
					
                case .gcm:
                    return CC_LONG(CC_SHA1_DIGEST_LENGTH)
				}

			#endif
		}
		
		#if os(Linux)
		
			// Hash, padding type
			public var algorithmForSignature: (OpaquePointer?, Int32) {
		
				switch self {
		
				case .sha1:
					return (.init(EVP_sha1()), RSA_PKCS1_PADDING)
		
				case .sha224:
					return (.init(EVP_sha224()), RSA_PKCS1_PADDING)
		
				case .sha256:
					return (.init(EVP_sha256()), RSA_PKCS1_PADDING)

				case .sha384:
					return (.init(EVP_sha384()), RSA_PKCS1_PADDING)

				case .sha512:
					return (.init(EVP_sha512()), RSA_PKCS1_PADDING)
                
                case .gcm:
                    return (.init(EVP_sha1()), RSA_PKCS1_PADDING)

				}
			}

			// HMAC type, symmetric encryption, padding type
			public var alogrithmForEncryption: (OpaquePointer?, OpaquePointer?, Int32) {
		
				switch self {
		
				case .sha1:
					return (.init(EVP_sha1()), .init(EVP_aes_256_cbc()), RSA_PKCS1_OAEP_PADDING)
		
				case .sha224:
					return (.init(EVP_sha224()), .init(EVP_aes_256_cbc()), RSA_PKCS1_OAEP_PADDING)
		
				case .sha256:
					return (.init(EVP_sha256()), .init(EVP_aes_256_cbc()), RSA_PKCS1_OAEP_PADDING)
		
				case .sha384:
					return (.init(EVP_sha384()), .init(EVP_aes_256_cbc()), RSA_PKCS1_OAEP_PADDING)
		
				case .sha512:
					return (.init(EVP_sha512()), .init(EVP_aes_128_gcm()), RSA_PKCS1_OAEP_PADDING)
                    
                case .gcm:
                    return (.init(EVP_sha1()), .init(EVP_aes_128_gcm()), RSA_PKCS1_OAEP_PADDING)
		
				}
			}

        #else
			
			@available(macOS 10.12, iOS 10.0, watchOS 3.3, tvOS 12.0, *)
			public var algorithmForSignature: SecKeyAlgorithm {
					
				switch self {
						
				case .sha1:
					return .rsaSignatureMessagePKCS1v15SHA1
						
				case .sha224:
					return .rsaSignatureMessagePKCS1v15SHA224
					
				case .sha256:
					return .rsaSignatureMessagePKCS1v15SHA256
						
				case .sha384:
					return .rsaSignatureMessagePKCS1v15SHA384
						
				case .sha512:
					return .rsaSignatureMessagePKCS1v15SHA512
                    
                case .gcm:
                    return .rsaSignatureMessagePKCS1v15SHA1
				}
			}
		
			@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
			var algorithmForPssSignature: SecKeyAlgorithm {
				switch self {
					
				case .sha1:
					return .rsaSignatureMessagePSSSHA1
					
				case .sha224:
					return .rsaSignatureMessagePSSSHA224
					
				case .sha256:
					return .rsaSignatureMessagePSSSHA256
					
				case .sha384:
					return .rsaSignatureMessagePSSSHA384
					
				case .sha512:
					return .rsaSignatureMessagePSSSHA512
					
				case .gcm:
					return .rsaSignatureMessagePSSSHA1
					
				}
			}
				
			@available(macOS 10.12, iOS 10.0, watchOS 3.3, tvOS 12.0, *)
			public var alogrithmForEncryption: SecKeyAlgorithm {
			
				switch self {
				
				case .sha1:
					return .rsaEncryptionOAEPSHA1AESGCM
				
				case .sha224:
					return .rsaEncryptionOAEPSHA224AESGCM
				
				case .sha256:
					return .rsaEncryptionOAEPSHA256AESGCM
				
				case .sha384:
					return .rsaEncryptionOAEPSHA384AESGCM
				
				case .sha512:
					return .rsaEncryptionOAEPSHA512AESGCM
                    
                case .gcm:
                    return .rsaEncryptionOAEPSHA1AESGCM
				
			}
		}
		
		#endif
		
		/// The platform/alogorithm dependent function to be used.
		/// (UnsafePointer<UInt8>!, Int, UnsafeMutablePointer<UInt8>!) -> UnsafeMutablePointer<UInt8>!
		#if os(Linux)
		
			public var engine: (_ data: UnsafePointer<UInt8>, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8>? {

				switch self {
					
				case .sha1:
					return SHA1
					
				case .sha224:
					return SHA224
					
				case .sha256:
					return SHA256
					
				case .sha384:
					return SHA384
					
				case .sha512:
					return SHA512
                    
                case .gcm:
                    return SHA1
					
				}
			}
		
		#else
		
			public var engine: (_ data: UnsafeRawPointer, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8>? {
			
				switch self {
					
				case .sha1:
					return CC_SHA1
					
				case .sha224:
					return CC_SHA224
					
				case .sha256:
					return CC_SHA256
					
				case .sha384:
					return CC_SHA384
					
				case .sha512:
					return CC_SHA512
					
                case .gcm:
                    return CC_SHA1
				}
		}
		
		#endif
	}
	
	
	// MARK: Functions
	
	///
	/// Return a digest of the data based on the alogorithm selected.
	///
	/// - Parameters:
	///		- alogorithm:		The digest `Alogorithm` to use.
	///
	/// - Returns:				`Data` containing the data in digest form.
	///
	public func digest(using alogorithm: Algorithm) throws -> Data {

		var hash = [UInt8](repeating: 0, count: Int(alogorithm.length))

		self.withUnsafeBytes { ptr in
			guard let baseAddress = ptr.baseAddress else { return }
			_ = alogorithm.engine(baseAddress.assumingMemoryBound(to: UInt8.self), CC_LONG(self.count), &hash)
		}
		
		return Data(hash)
	}
}
