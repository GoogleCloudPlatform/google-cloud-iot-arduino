//
//  KeyDerivation.swift
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
/// Derives key material from a password or passphrase.
///
public class PBKDF {
	
    /// Enumerates available pseudo random algorithms
	public enum PseudoRandomAlgorithm {
		
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
			///  Return the OS native value
			func nativeValue() -> CCPseudoRandomAlgorithm {
			
            	switch self {
		
	            case .sha1:
					return CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1)
				case .sha224:
					return CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA224)
				case .sha256:
					return CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256)
				case .sha384:
					return CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA384)
				case .sha512:
					return CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512)
        	    }
        	}
		
		#elseif os(Linux)
		
			///  Return the OS native value
			func nativeValue() -> OpaquePointer? {
		
				switch self {
				
				case .sha1:
					return .init(EVP_sha1())
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
    }

    ///
    /// Determines the (approximate) number of iterations of the key derivation algorithm that need
    /// to be run to achieve a particular delay (or calculation time).
    ///
    /// - Parameters:
 	///		- passwordLength: 	Password length in bytes
    /// 	- saltLength: 		Salt length in bytes
    /// 	- algorithm: 		The PseudoRandomAlgorithm to use
    /// 	- derivedKeyLength: The desired key length
    /// 	- msec: 			The desired calculation time
	///
    /// - Returns: The number of times the algorithm should be run
    ///
	public class func calibrate(passwordLength: Int, saltLength: Int, algorithm: PseudoRandomAlgorithm, derivedKeyLength: Int, msec: UInt32) -> UInt {
		
		#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	        return UInt(CCCalibratePBKDF(CCPBKDFAlgorithm(kCCPBKDF2), passwordLength, saltLength, algorithm.nativeValue(), derivedKeyLength, msec))
		#elseif os(Linux)
			// Value as per RFC 2898.
			return UInt(1000 * UInt(msec))
		#endif
    }
    

    /// 
    /// Derives key material from a password and salt.
    ///
    /// - Parameters:
 	///		- password: 		The password string, will be converted using UTF8
    /// 	- salt: 			The salt string will be converted using UTF8
    /// 	- prf: 				The pseudo random function
    /// 	- round: 			The number of rounds
    /// 	- derivedKeyLength: The length of the desired derived key, in bytes.
	///
    /// - Returns: The derived key
    ///
	public class func deriveKey(fromPassword password: String, salt: String, prf: PseudoRandomAlgorithm, rounds: uint, derivedKeyLength: UInt) throws -> [UInt8] {
		
		var derivedKey = Array<UInt8>(repeating: 0, count:Int(derivedKeyLength))
		#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
			let status: Int32 = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), password, password.utf8.count, salt, salt.utf8.count, prf.nativeValue(), rounds, &derivedKey, derivedKey.count)
			if status != Int32(kCCSuccess) {
			
    	        throw CryptorError.fail(status, "ERROR: CCKeyDerivationPBDK failed with status \(status).")
        	}
		#elseif os(Linux)
			let status = PKCS5_PBKDF2_HMAC(password, Int32(password.utf8.count), salt, Int32(salt.utf8.count), Int32(rounds), .make(optional: prf.nativeValue()), Int32(derivedKey.count), &derivedKey)
			if status != 1 {
				let error = ERR_get_error()

				throw CryptorError.fail(Int32(error), "ERROR: PKCS5_PBKDF2_HMAC failed, reason: \(errToString(ERR_error_string(error, nil)))")
			}
		#endif
        return derivedKey
    }
    
    ///
    /// Derives key material from a password and salt.
    ///
    /// - Parameters: 
	///		- password: 		The password string, will be converted using UTF8
    /// 	- salt: 			The salt array of bytes
    /// 	- prf: 				The pseudo random function
    /// 	- round: 			The number of rounds
    /// 	- derivedKeyLength: The length of the desired derived key, in bytes.
	///
    /// - Returns: The derived key
    ///
	public class func deriveKey(fromPassword password: String, salt: [UInt8], prf: PseudoRandomAlgorithm, rounds: uint, derivedKeyLength: UInt) throws -> [UInt8] {
		
		var derivedKey = Array<UInt8>(repeating: 0, count:Int(derivedKeyLength))
		#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
			let status: Int32 = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), password, password.utf8.count, salt, salt.count, prf.nativeValue(), rounds, &derivedKey, derivedKey.count)
			if status != Int32(kCCSuccess) {
	
	            throw CryptorError.fail(status, "ERROR: CCKeyDerivationPBDK failed with status \(status).")
        	}
		#elseif os(Linux)
			let status = PKCS5_PBKDF2_HMAC(password, Int32(password.utf8.count), salt, Int32(salt.count), Int32(rounds), .make(optional: prf.nativeValue()), Int32(derivedKey.count), &derivedKey)
			if status != 1 {
				let error = ERR_get_error()

				throw CryptorError.fail(Int32(error), "ERROR: PKCS5_PBKDF2_HMAC failed, reason: \(errToString(ERR_error_string(error, nil)))")
			}
		#endif
        return derivedKey
    }
    
    ///
    /// Derives key material from a password buffer.
    ///
    /// - Parameters:
 	///		- password: 		Pointer to the password buffer
    /// 	- passwordLength: 	Password length in bytes
    /// 	- salt: 			Pointer to the salt buffer
    /// 	- saltLength: 		Salt length in bytes
    /// 	- prf: 				The PseudoRandomAlgorithm to use
    /// 	- rounds: 			The number of rounds of the algorithm to use
    /// 	- derivedKey: 		Pointer to the derived key buffer.
    /// 	- derivedKeyLength:	The desired key length
	///
    /// - Returns: The number of times the algorithm should be run
    ///
	public class func deriveKey(fromPassword password: UnsafePointer<Int8>, passwordLen: Int, salt: UnsafePointer<UInt8>, saltLen: Int, prf: PseudoRandomAlgorithm, rounds: uint, derivedKey: UnsafeMutablePointer<UInt8>, derivedKeyLen: Int) throws {
		
		#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        	let status: Int32 = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), password, passwordLen, salt, saltLen, prf.nativeValue(), rounds, derivedKey, derivedKeyLen)
			if status != Int32(kCCSuccess) {
			
	            throw CryptorError.fail(status, "ERROR: CCKeyDerivationPBDK failed with status \(status).")
    	    }
		#elseif os(Linux)
			let status = PKCS5_PBKDF2_HMAC(password, Int32(passwordLen), salt, Int32(saltLen), Int32(rounds), .make(optional: prf.nativeValue()), Int32(derivedKeyLen), derivedKey)
			if status != 1 {
				let error = ERR_get_error()

				throw CryptorError.fail(Int32(error), "ERROR: PKCS5_PBKDF2_HMAC failed, reason: \(errToString(ERR_error_string(error, nil)))")
			}
		#endif
	}
}
