//
//  HMAC.swift
//  Cryptor
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

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	import CommonCrypto
#elseif os(Linux)
	import OpenSSL
#endif

///
/// Calculates a cryptographic Hash-Based Message Authentication Code (HMAC).
///
public class HMAC: Updatable {
	
    ///
    /// Enumerates available algorithms.
    ///
    public enum Algorithm {
		
        /// Message Digest 5
        case md5
		
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
        
		#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
		
			static let fromNative: [CCHmacAlgorithm: Algorithm] = [
                CCHmacAlgorithm(kCCHmacAlgSHA1): .sha1,
                CCHmacAlgorithm(kCCHmacAlgSHA1): .md5,
                CCHmacAlgorithm(kCCHmacAlgSHA256): .sha256,
                CCHmacAlgorithm(kCCHmacAlgSHA384): .sha384,
                CCHmacAlgorithm(kCCHmacAlgSHA512): .sha512,
                CCHmacAlgorithm(kCCHmacAlgSHA224): .sha224
            ]

			static func fromNativeValue(nativeAlg: CCHmacAlgorithm) -> Algorithm? {
			
				return fromNative[nativeAlg]
			}
		
			func nativeValue() -> CCHmacAlgorithm {
			
				switch self {
				
				case .sha1:
					return CCHmacAlgorithm(kCCHmacAlgSHA1)
				case .md5:
					return CCHmacAlgorithm(kCCHmacAlgMD5)
				case .sha224:
					return CCHmacAlgorithm(kCCHmacAlgSHA224)
				case .sha256:
					return CCHmacAlgorithm(kCCHmacAlgSHA256)
				case .sha384:
					return CCHmacAlgorithm(kCCHmacAlgSHA384)
				case .sha512:
					return CCHmacAlgorithm(kCCHmacAlgSHA512)
				}
			}
		
		#elseif os(Linux)
		
			func nativeValue() -> OpaquePointer? {
	
				switch self {
	
				case .sha1:
					return .init(EVP_sha1())
				case .md5:
					return .init(EVP_md5())
				case .sha224:
					return .init(EVP_sha224())
				case .sha256:
					return .init(EVP_sha256())
				case .sha384:
					return .init(EVP_sha384())
				case .sha512:
					return .init(EVP_sha512())
				}
			}
		
		#endif
		
        ///
        /// Obtains the digest length produced by this algorithm (in bytes).
        ///
        public func digestLength() -> Int {
			
			#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
				
				switch self {
					
				case .sha1:
					return Int(CC_SHA1_DIGEST_LENGTH)
				case .md5:
					return Int(CC_MD5_DIGEST_LENGTH)
				case .sha224:
					return Int(CC_SHA224_DIGEST_LENGTH)
				case .sha256:
					return Int(CC_SHA256_DIGEST_LENGTH)
				case .sha384:
					return Int(CC_SHA384_DIGEST_LENGTH)
				case .sha512:
					return Int(CC_SHA512_DIGEST_LENGTH)
				}
				
			#elseif os(Linux)
				
				switch self {
					
				case .sha1:
					return Int(SHA_DIGEST_LENGTH)
				case .md5:
					return Int(MD5_DIGEST_LENGTH)
				case .sha224:
					return Int(SHA224_DIGEST_LENGTH)
				case .sha256:
					return Int(SHA256_DIGEST_LENGTH)
				case .sha384:
					return Int(SHA384_DIGEST_LENGTH)
				case .sha512:
					return Int(SHA512_DIGEST_LENGTH)
				}
			
			#endif
			
        }
    }
	
	/// Context
	#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	
    	typealias Context = UnsafeMutablePointer<CCHmacContext>
	
	#elseif os(Linux)
	
		typealias Context = OpaquePointer?
	
	#endif
    
    /// Status of the calculation
    public internal(set) var status: Status = .success
	
	#if os(Linux)
		private let context = HMAC_CTX_new_wrapper()
	#else
		private let context = Context.allocate(capacity: 1)
	#endif
    private var algorithm: Algorithm
    
	// MARK: Lifecycle Methods
	
	///
	/// Creates a new HMAC instance with the specified algorithm and key.
	///
	/// - Parameters:
 	///		- algorithm: 	Selects the algorithm
	/// 	- keyBuffer: 	Specifies pointer to the key
	///		- keyByteCount: Number of bytes on keyBuffer
	///
	init(using algorithm: Algorithm, keyBuffer: UnsafeRawPointer, keyByteCount: Int) {
		
        self.algorithm = algorithm
		#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	        CCHmacInit(context, algorithm.nativeValue(), keyBuffer, size_t(keyByteCount))
		#elseif os(Linux)
			HMAC_Init_wrapper(context, keyBuffer, Int32(keyByteCount), .make(optional: algorithm.nativeValue()))
		#endif
    }
    
	///
	/// Creates a new HMAC instance with the specified algorithm and key.
	///
	/// - Parameters:
	///		- algorithm: 	Selects the algorithm
	/// 	- key: 			Specifies the key as Data
	///
	public init(using algorithm: Algorithm, key: Data) {
		
		self.algorithm = algorithm
		#if swift(>=5.0)
			#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
				key.withUnsafeBytes() {
					CCHmacInit(context, algorithm.nativeValue(), $0.baseAddress, size_t(key.count))
				}
				#elseif os(Linux)
				_ = key.withUnsafeBytes() {
					HMAC_Init_wrapper(context, $0.baseAddress, Int32(key.count), .make(optional: algorithm.nativeValue()))
				}
			#endif
		#else
			#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
				key.withUnsafeBytes() { (buffer: UnsafePointer<UInt8>) in
					CCHmacInit(context, algorithm.nativeValue(), buffer, size_t(key.count))
				}
			#elseif os(Linux)
				_ = key.withUnsafeBytes() { (buffer: UnsafePointer<UInt8>) in
					HMAC_Init_wrapper(context, buffer, Int32(key.count), .make(optional: algorithm.nativeValue()))
				}
			#endif
		#endif
	}
	
    ///
    /// Creates a new HMAC instance with the specified algorithm and key.
    ///
    /// - Parameters:
 	///		- algorithm: 	Selects the algorithm
    /// 	- key: 			Specifies the key as NSData
    ///
	public init(using algorithm: Algorithm, key: NSData) {
		
        self.algorithm = algorithm
		#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        	CCHmacInit(context, algorithm.nativeValue(), key.bytes, size_t(key.length))
		#elseif os(Linux)
			HMAC_Init_wrapper(context, key.bytes, Int32(key.length), .make(optional: algorithm.nativeValue()))
		#endif
    }
    
    ///
    /// Creates a new HMAC instance with the specified algorithm and key.
    ///
    /// - Parameters:
 	///		- algorithm: 	Selects the algorithm
    /// 	- key: 			Specifies the key as byte array.
    ///
	public init(using algorithm: Algorithm, key: [UInt8]) {
		
        self.algorithm = algorithm
		#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        	CCHmacInit(context, algorithm.nativeValue(), key, size_t(key.count))
		#elseif os(Linux)
			HMAC_Init_wrapper(context, key, Int32(key.count), .make(optional: algorithm.nativeValue()))
		#endif
    }
    
    ///
    /// Creates a new HMAC instance with the specified algorithm and key string.
    /// The key string is converted to bytes using UTF8 encoding.
    ///
    /// - Parameters:
 	///		- algorithm: 	Selects the algorithm
    /// 	- key: 			Specifies the key as String
    ///
	public init(using algorithm: Algorithm, key: String) {
		
        self.algorithm = algorithm
		#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        	CCHmacInit(context, algorithm.nativeValue(), key, size_t(key.lengthOfBytes(using: String.Encoding.utf8)))
		#elseif os(Linux)
			HMAC_Init_wrapper(context, key, Int32(key.utf8.count), .make(optional: algorithm.nativeValue()))
		#endif
    }
	
	///
	/// Cleanup
	///
    deinit {
        #if os(Linux)
			HMAC_CTX_free_wrapper(.make(optional: context))
        #else
			#if swift(>=4.1)
				context.deallocate()
			#else
				context.deallocate(capacity: 1)
			#endif
		#endif
    }
 
	// MARK: Public Methods
	
    ///
    /// Updates the calculation of the HMAC with the contents of a buffer.
	///
	/// - Parameter buffer: Update buffer
    ///
    /// - Returns: The 'in-progress' calculated HMAC
    ///
	public func update(from buffer: UnsafeRawPointer, byteCount: size_t) -> Self? {
		
		#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	        CCHmacUpdate(context, buffer, byteCount)
		#elseif os(Linux)
			HMAC_Update(context, buffer.assumingMemoryBound(to: UInt8.self), byteCount)
		#endif
        return self
    }
    
    ///
    /// Finalizes the HMAC calculation
    ///
    /// - Returns: The final calculated HMAC
    ///
	public func final() -> [UInt8] {
		
		var hmac = Array<UInt8>(repeating: 0, count:algorithm.digestLength())
		#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        	CCHmacFinal(context, &hmac)
		#elseif os(Linux)
			var length: UInt32 = 0
			HMAC_Final(context, &hmac, &length)
		#endif
        return hmac
    }
}

