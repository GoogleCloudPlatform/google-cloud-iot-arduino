//
//  CryptorRSAKey.swift
//  CryptorRSA
//
//  Created by Bill Abt on 1/18/17.
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

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	import CommonCrypto
#elseif os(Linux)
	import OpenSSL
#endif

import Foundation

// MARK: -

@available(macOS 10.12, iOS 10.3, watchOS 3.3, tvOS 12.0, *)
extension CryptorRSA {
	
	// MARK: Type Aliases
	
	#if os(Linux)
	
		public typealias NativeKey = OpaquePointer?
	
	#else
	
		public typealias NativeKey = SecKey
	
	#endif
	
	// MARK: Class Functions
	
	// MARK: -- Public Key Creation
	
	///
	/// Creates a public key with DER data.
	///
	/// - Parameters:
	///		- data: 			Key data
	///
	/// - Returns:				New `PublicKey` instance.
	///
	public class func createPublicKey(with data: Data) throws -> PublicKey {
		
		return try PublicKey(with: data)
	}
	
	///
	/// Creates a public key by extracting it from a certificate.
	///
	/// - Parameters:
	/// 	- data:				`Data` representing the certificate.
	///
	/// - Returns:				New `PublicKey` instance.
	///
	public class func createPublicKey(extractingFrom data: Data) throws -> PublicKey {
		
        // Extact the data as a base64 string...
        let str = String(data: data, encoding: .utf8)
        guard let tmp = str else {
            
            throw Error(code: ERR_CREATE_CERT_FAILED, reason: "Unable to create certificate from certificate data, incorrect format.")
        }
    
        // Get the Base64 representation of the PEM encoded string after stripping off the PEM markers...
        let base64 = try CryptorRSA.base64String(for: tmp)
        let data = Data(base64Encoded: base64)!
		
		// Call the internal function to finish up...
		return try CryptorRSA.createPublicKey(data: data)
		
	}
	
	///
	/// Creates a key with a base64-encoded string.
	///
	/// - Parameters:
	///		- base64String: 	Base64-encoded key data
	///
	/// - Returns:				New `PublicKey` instance.
	///
	public class func createPublicKey(withBase64 base64String: String) throws -> PublicKey {
		
		guard let data = Data(base64Encoded: base64String, options: [.ignoreUnknownCharacters]) else {
			
			throw Error(code: ERR_INIT_PK, reason: "Couldn't decode base64 string")
		}
		
		return try PublicKey(with: data)
	}
	
	///
	/// Creates a key with a PEM string.
	///
	/// - Parameters:
	///		- pemString: 		PEM-encoded key string
	///
	/// - Returns:				New `PublicKey` instance.
	///
	public class func createPublicKey(withPEM pemString: String) throws -> PublicKey {
		
        // Get the Base64 representation of the PEM encoded string after stripping off the PEM markers
        let base64String = try CryptorRSA.base64String(for: pemString)
    
        return try createPublicKey(withBase64: base64String)
		
	}
	
	///
	/// Creates a key with a PEM file.
	///
	/// - Parameters:
	/// 	- pemName: 			Name of the PEM file
	/// 	- path: 			Path where the file is located.
	///
	/// - Returns:				New `PublicKey` instance.
	///
	public class func createPublicKey(withPEMNamed pemName: String, onPath path: String) throws -> PublicKey {
		
		var certName = pemName
		if !pemName.hasSuffix(PEM_SUFFIX) {
			
			certName = pemName.appending(PEM_SUFFIX)
		}
		
		let fullPath = URL(fileURLWithPath: #file).appendingPathComponent( path.appending(certName) ).standardized
		
		let keyString = try String(contentsOf: fullPath, encoding: .utf8)
		
		return try createPublicKey(withPEM: keyString)
	}
	
	///
	/// Creates a key with a DER file.
	///
	/// - Parameters:
	/// 	- derName: 			Name of the DER file
	/// 	- path: 			Path where the file is located.
	///
	/// - Returns:				New `PublicKey` instance.
	///
	public class func createPublicKey(withDERNamed derName: String, onPath path: String) throws -> PublicKey {
		
		var certName = derName
		if !derName.hasSuffix(DER_SUFFIX) {
			
			certName = derName.appending(DER_SUFFIX)
		}
		
		let fullPath = URL(fileURLWithPath: #file).appendingPathComponent( path.appending(certName) ).standardized
		
		let data = try Data(contentsOf: fullPath)
		
		return try PublicKey(with: data)
	}
	
	///
	/// Creates a public key by extracting it from a certificate.
	///
	/// - Parameters:
	/// 	- certName:			Name of the certificate file.
	/// 	- path: 			Path where the file is located.
	///
	/// - Returns:				New `PublicKey` instance.
	///
	public class func createPublicKey(extractingFrom certName: String, onPath path: String) throws -> PublicKey {
		
		var certNameFull = certName
		if !certName.hasSuffix(CER_SUFFIX) {
			
			certNameFull = certName.appending(CER_SUFFIX)
		}
		
		let fullPath = URL(fileURLWithPath: #file).appendingPathComponent( path.appending(certNameFull) ).standardized
		
        // Get the Base64 representation of the PEM encoded string after stripping off the PEM markers...
        let tmp = try String(contentsOf: fullPath, encoding: .utf8)
        let base64 = try CryptorRSA.base64String(for: tmp)
        let data = Data(base64Encoded: base64)!
				
		return try CryptorRSA.createPublicKey(data: data)
	}
	
	///
	/// Creates a key with a PEM file.
	///
	/// - Parameters:
	/// 	- pemName: 			Name of the PEM file
	/// 	- bundle: 			Bundle in which to look for the PEM file. Defaults to the main bundle.
	///
	/// - Returns:				New `PublicKey` instance.
	///
	public class func createPublicKey(withPEMNamed pemName: String, in bundle: Bundle = Bundle.main) throws -> PublicKey {
		
		guard let path = bundle.path(forResource: pemName, ofType: PEM_SUFFIX) else {
			
			throw Error(code: ERR_INIT_PK, reason: "Couldn't find a PEM file named '\(pemName)'")
		}
		
		let keyString = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
		
		return try createPublicKey(withPEM: keyString)
	}
	
	///
	/// Creates a key with a DER file.
	///
	/// - Parameters:
	/// 	- derName: 			Name of the DER file
	/// 	- bundle: 			Bundle in which to look for the DER file. Defaults to the main bundle.
	///
	/// - Returns:				New `PublicKey` instance.
	///
	public class func createPublicKey(withDERNamed derName: String, in bundle: Bundle = Bundle.main) throws -> PublicKey {
		
		guard let path = bundle.path(forResource: derName, ofType: DER_SUFFIX) else {
			
			throw Error(code: ERR_INIT_PK, reason: "Couldn't find a DER file named '\(derName)'")
		}
		
		let data = try Data(contentsOf: URL(fileURLWithPath: path))
		
		return try PublicKey(with: data)
	}
	
	///
	/// Creates a public key by extracting it from a certificate.
	///
	/// - Parameters:
	/// 	- certName:			Name of the certificate file.
	/// 	- bundle: 			Bundle in which to look for the DER file. Defaults to the main bundle.
	///
	/// - Returns:				New `PublicKey` instance.
	///
	public class func createPublicKey(extractingFrom certName: String, in bundle: Bundle = Bundle.main) throws -> PublicKey {
		
		guard let path = bundle.path(forResource: certName, ofType: CER_SUFFIX) else {
			
			throw Error(code: ERR_INIT_PK, reason: "Couldn't find a certificate file named '\(certName)'")
		}
		
		// Import the data from the file...
		let tmp = try String(contentsOf: URL(fileURLWithPath: path))
		let base64 = try CryptorRSA.base64String(for: tmp)
		let data = Data(base64Encoded: base64)!
		
		// Call the internal function to finish up...
		return try CryptorRSA.createPublicKey(data: data)
	}
	
	///
	/// Creates a public key by extracting it from certificate data.
	///
	/// - Parameters:
	/// 	- data:				`Data` representing the certificate.
	///
	/// - Returns:				New `PublicKey` instance.
	///
	internal class func createPublicKey(data: Data) throws -> PublicKey {
		
		#if os(Linux)
		
			let certbio = BIO_new(BIO_s_mem())
			defer {
				BIO_free(certbio)
			}
		
			// Move the key data to BIO
			try data.withUnsafeBytes() { (buffer: UnsafeRawBufferPointer) in
				
				let len = BIO_write(certbio, buffer.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(data.count))
				guard len != 0 else {
					let source = "Couldn't create BIO reference from key data"
					if let reason = CryptorRSA.getLastError(source: source) {
						
						throw Error(code: ERR_ADD_KEY, reason: reason)
					}
					throw Error(code: ERR_ADD_KEY, reason: source + ": No OpenSSL error reported.")
				}
				
				// The below is equivalent of BIO_flush...
				BIO_ctrl(certbio, BIO_CTRL_FLUSH, 0, nil)
			}
			let cert = d2i_X509_bio(certbio, nil)
			if cert == nil {
				print("Error loading cert into memory\n")
				throw Error(code: ERR_CREATE_CERT_FAILED, reason: "Error loading cert into memory.")
			}
		
			// Extract the certificate's public key data.
			let evp_key: OpaquePointer? = .init(X509_get_pubkey(cert))
			if evp_key == nil {
				throw Error(code: ERR_CREATE_CERT_FAILED, reason: "Error getting public key from certificate")
			}
		
			return PublicKey(with: evp_key)
	
		#else
		
			// Create a DER-encoded X.509 certificate object from the DER data...
			let certificateData = SecCertificateCreateWithData(nil, data as CFData)
			guard let certData = certificateData else {
				
				throw Error(code: ERR_CREATE_CERT_FAILED, reason: "Unable to create certificate from certificate data.")
			}
			
			var key: SecKey? = nil
		
			#if swift(>=4.2)
		
				if #available(macOS 10.14, iOS 12.0, watchOS 5.0, *) {
					
					key = SecCertificateCopyKey(certData)
					
				}
		
			#endif
		
			if key == nil {
		
				#if os(macOS)
			
					// Now extract the public key from it...
					let status: OSStatus = withUnsafeMutablePointer(to: &key) { ptr in
						
						// Retrieves the public key from a certificate...
						SecCertificateCopyPublicKey(certData, UnsafeMutablePointer(ptr))
					}
					if status != errSecSuccess {
						
						throw Error(code: ERR_EXTRACT_PUBLIC_KEY_FAILED, reason: "Unable to extract public key from data.")
					}
			
				#else
			
					key = SecCertificateCopyPublicKey(certData)
			
				#endif
			}
		
			guard let createdKey = key else {
				
				throw Error(code: ERR_EXTRACT_PUBLIC_KEY_FAILED, reason: "Unable to extract public key from data.")
			}
			
			return PublicKey(with: createdKey)
			
		#endif		
	}
	
	// MARK: -- Private Key Creation
	
	///
	/// Creates a private key with data.
	///
	/// - Parameters:
	///		- data: 			Key data
	///
	/// - Returns:				New `PrivateKey` instance.
	///
	public class func createPrivateKey(with data: Data) throws -> PrivateKey {
		
		return try PrivateKey(with: data)
	}
	
	///
	/// Creates a key with a base64-encoded string.
	///
	/// - Parameters:
	///		- base64String: 	Base64-encoded key data
	///
	/// - Returns:				New `PrivateKey` instance.
	///
	public class func createPrivateKey(withBase64 base64String: String) throws -> PrivateKey {
		
		guard let data = Data(base64Encoded: base64String, options: [.ignoreUnknownCharacters]) else {
			
			throw Error(code: ERR_INIT_PK, reason: "Couldn't decode base 64 string")
		}
        
		return try PrivateKey(with: data)
	}
	
	///
	/// Creates a key with a PEM string.
	///
	/// - Parameters:
	///		- pemString: 		PEM-encoded key string
	///
	/// - Returns:				New `PrivateKey` instance.
	///
	public class func createPrivateKey(withPEM pemString: String) throws -> PrivateKey {
		
        let base64String = try CryptorRSA.base64String(for: pemString)
    
        return try CryptorRSA.createPrivateKey(withBase64: base64String)
		
	}
	
	///
	/// Creates a key with a PEM file.
	///
	/// - Parameters:
	/// 	- pemName: 			Name of the PEM file
	/// 	- path: 			Path where the file is located.
	///
	/// - Returns:				New `PrivateKey` instance.
	///
	public class func createPrivateKey(withPEMNamed pemName: String, onPath path: String) throws -> PrivateKey {
		
		var certName = pemName
		if !pemName.hasSuffix(PEM_SUFFIX) {
			
			certName = pemName.appending(PEM_SUFFIX)
		}
		let fullPath = URL(fileURLWithPath: #file).appendingPathComponent( path.appending(certName) ).standardized
		
		let keyString = try String(contentsOf: fullPath, encoding: .utf8)
		
		return try CryptorRSA.createPrivateKey(withPEM: keyString)
	}
	
	///
	/// Creates a key with a DER file.
	///
	/// - Parameters:
	/// 	- derName: 			Name of the DER file
	/// 	- path: 			Path where the file is located.
	///
	/// - Returns:				New `PrivateKey` instance.
	///
	public class func createPrivateKey(withDERNamed derName: String, onPath path: String) throws -> PrivateKey {
		
		var certName = derName
		if !derName.hasSuffix(DER_SUFFIX) {
			
			certName = derName.appending(DER_SUFFIX)
		}
		let fullPath = URL(fileURLWithPath: #file).appendingPathComponent( path.appending(certName) ).standardized
		
		let data = try Data(contentsOf: fullPath)
		
		return try PrivateKey(with: data)
	}
	
	///
	/// Creates a key with a PEM file.
	///
	/// - Parameters:
	/// 	- pemName: 			Name of the PEM file
	/// 	- bundle: 			Bundle in which to look for the PEM file. Defaults to the main bundle.
	///
	/// - Returns:				New `PrivateKey` instance.
	///
	public class func createPrivateKey(withPEMNamed pemName: String, in bundle: Bundle = Bundle.main) throws -> PrivateKey {
		
		guard let path = bundle.path(forResource: pemName, ofType: PEM_SUFFIX) else {
			
			throw Error(code: ERR_INIT_PK, reason: "Couldn't find a PEM file named '\(pemName)'")
		}
		
		let keyString = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
		
		return try CryptorRSA.createPrivateKey(withPEM: keyString)
	}
	
	///
	/// Creates a key with a DER file.
	///
	/// - Parameters:
	/// 	- derName: 			Name of the DER file
	/// 	- bundle: 			Bundle in which to look for the DER file. Defaults to the main bundle.
	///
	/// - Returns:				New `PrivateKey` instance.
	///
	public class func createPrivateKey(withDERNamed derName: String, in bundle: Bundle = Bundle.main) throws -> PrivateKey {
		
		guard let path = bundle.path(forResource: derName, ofType: DER_SUFFIX) else {
			
			throw Error(code: ERR_INIT_PK, reason: "Couldn't find a DER file named '\(derName)'")
		}
		
		let data = try Data(contentsOf: URL(fileURLWithPath: path))
		
		return try PrivateKey(with: data)
	}
	
    /// Create a new RSA public/private key pair.
    ///
    /// - Parameters:
    ///     - keySize: 	The size of the generated RSA keys in bits.
	///
    /// - Returns: 		A tuple containing the (`PrivateKey`, `PublicKey`) instances.
	///
	public class func makeKeyPair(_ keySize: RSAKey.KeySize) throws -> (PrivateKey, PublicKey) {
		
        #if os(Linux)
			var pkey = EVP_PKEY_new()
			let ctx = EVP_PKEY_CTX_new_id(EVP_PKEY_RSA, nil)
			defer {
				EVP_PKEY_CTX_free(ctx)
			}
			guard EVP_PKEY_keygen_init(ctx) == 1,
				EVP_PKEY_CTX_ctrl(ctx, -1, EVP_PKEY_OP_KEYGEN, EVP_PKEY_CTRL_RSA_KEYGEN_BITS, Int32(keySize.bits), nil) == 1,
				EVP_PKEY_keygen(ctx, &pkey) == 1
				else {
					EVP_PKEY_free(pkey)
					throw Error(code: ERR_INIT_PK, reason: "Could not generate rsa pair for \(keySize.bits) bits")
			}
			let privKey = PrivateKey(with: .make(optional: pkey))
			let publicPem = try RSAKey.getPEMString(reference: privKey.reference, keyType: .publicType, stripped: false)
			let pubKey = try CryptorRSA.createPublicKey(withPEM: publicPem)

			return(privKey, pubKey)

        #else

			let parameters: [String: AnyObject] = [
				kSecAttrKeyType as String:          kSecAttrKeyTypeRSA,
				kSecAttrKeySizeInBits as String:    keySize.bits as AnyObject,
				kSecPublicKeyAttrs as String: [ kSecAttrIsPermanent as String: true as AnyObject ] as AnyObject,
				kSecPrivateKeyAttrs as String: [ kSecAttrIsPermanent as String: true as AnyObject ] as AnyObject,
				]
			var pubKey, privKey: SecKey?
			let status = SecKeyGeneratePair(parameters as CFDictionary, &pubKey, &privKey)
			guard status == 0, let newPubKey = pubKey, let newPrivKey = privKey else {
				throw Error(code: ERR_INIT_PK, reason: "Could not generate rsa pair for \(keySize.bits) bits")
			}
			let privateKey = PrivateKey(with: newPrivKey)
			let publicKey = PublicKey(with: newPubKey)

			return (privateKey, publicKey)
        #endif
	}
    
	
	// MARK: -
	
	///
	/// RSA Key Creation and Handling
	///
	public class RSAKey {
		
		// MARK: Enums
		
		/// Denotes the type of key this represents.
		public enum KeyType {
			
			/// Public
			case publicType
			
			/// Private
			case privateType
		}
		
		/// Denotes the size of the RSA key.
		public struct KeySize {
			let bits: Int
			/// A 1024 bit RSA key. Not recommended since this may become breakable in the near future.
			public static let bits1024 = KeySize(bits: 1024)
			/// A 2048 bit RSA key. Recommended if security will not be required beyond 2030.
			public static let bits2048 = KeySize(bits: 2048)
			/// A 3072 bit RSA key. Recommended if security is required beyond 2030.
			public static let bits3072 = KeySize(bits: 3072)
			/// A 4096 bit RSA key.
			public static let bits4096 = KeySize(bits: 4096)
		}
		
		// MARK: Properties
		
		/// The RSA key as a PKCS#1 PEM String
		public let pemString: String
		
		/// The stored key
		internal let reference: NativeKey
        
        #if os(Linux)
        	var publicKeyBytes: Data?
			deinit {
				EVP_PKEY_free(.make(optional: reference))
			}
        #endif
        
		/// Represents the type of key data contained.
		public internal(set) var type: KeyType = .publicType
		
		// MARK: Initializers
		
		///
		/// Create a key using key data (in DER format).
		///
		/// - Parameters:
		///		- data: 			Key data.
		///		- type:				Type of key data.
		///
		/// - Returns:				New `RSAKey` instance.
		///
		internal init(with data: Data, type: KeyType) throws {
			
			var data = data
			
			// If data is a PEM String, strip the headers and convert to der.
			if let pemString = String(data: data, encoding: .utf8),
				let base64String = try? CryptorRSA.base64String(for: pemString),
				let base64Data = Data(base64Encoded: base64String) {
				data = base64Data
			}
			data = try CryptorRSA.stripX509CertificateHeader(for: data)
			self.pemString = CryptorRSA.convertDerToPem(from: data, type: type)
			self.type = type            
            reference = try CryptorRSA.createKey(from: data, type: type)
			#if os(Linux)
			if let pubString = try? RSAKey.getPEMString(reference: reference, keyType: .publicType, stripped: true),
				let base64String = try? CryptorRSA.base64String(for: pubString),
				let derData = Data(base64Encoded: base64String)	{
				self.publicKeyBytes = derData
			}
			#endif
		}
		
		///
		/// Create a key using a native key.
		///
		/// - Parameters:
		///		- nativeKey:		Native key representation.
		///		- type:				Type of key.
		///
		/// - Returns:				New `RSAKey` instance.
		///
		internal init(with nativeKey: NativeKey, type: KeyType) {
			
			self.type = type
			self.reference = nativeKey
			self.pemString = (try? RSAKey.getPEMString(reference: nativeKey, type: type)) ?? ""
			#if os(Linux)
			if let base64String = try? CryptorRSA.base64String(for: pemString),
				let derData = Data(base64Encoded: base64String)	{
				self.publicKeyBytes = derData
			}
			#endif
		}
		
		#if os(Linux) && !swift(>=4.1)
		
			///
			/// Create a key using a native key.
			///
			/// - Parameters:
			///		- nativeKey:		Pointer to RSA key structure.
			///		- type:				Type of key.
			///
			/// - Returns:				New `RSAKey` instance.
			///
			internal init(with nativeKey: UnsafeMutablePointer<EVP_PKEY>, type: KeyType) {
				
				self.type = type
				self.reference = .make(optional: nativeKey)
				self.pemString = (try? RSAKey.getPEMString(reference: .init(nativeKey), type: type)) ?? ""
				if let base64String = try? CryptorRSA.base64String(for: pemString),
					let derData = Data(base64Encoded: base64String)	{
					self.publicKeyBytes = derData
				}
			}
		
		#endif

		///
		/// Get the RSA key as a PEM String.
		///
		/// - Returns: The RSA Key in PEM format.
		///
		static func getPEMString(reference: NativeKey, type: KeyType) throws -> String {

			#if os(Linux)
				return try getPEMString(reference: reference, keyType: type, stripped: true)
			#else
				var error: Unmanaged<CFError>? = nil
				guard let keyBytes = SecKeyCopyExternalRepresentation(reference, &error) else {
					guard let error = error?.takeRetainedValue() else {
						throw Error(code: ERR_INIT_PK, reason: "Couldn't read PEM String")
					}
					throw error
				}
				return CryptorRSA.convertDerToPem(from: keyBytes as Data, type: type)
			#endif            
		}
		
		#if os(Linux)
			///
			///	Get a PEM string of a native key.
			///
			///	- Parameters:
			///		- reference:		Native key.
			///		- keyType:			Type of key.
			///		- stripped:			`true` to return string stripped, `false` otherwise.
			///
			///	- Returns:				The PEM string.
			///
			static func getPEMString(reference: NativeKey, keyType: KeyType, stripped: Bool) throws -> String {
				let asn1Bio = BIO_new(BIO_s_mem())
				defer { BIO_free_all(asn1Bio) }
				if keyType == .publicType {
					PEM_write_bio_PUBKEY(asn1Bio, .make(optional: reference))
				} else {
					PEM_write_bio_PrivateKey(asn1Bio, .make(optional: reference), nil, nil, 0, nil, nil)
				}
				// 4096 bit rsa PEM key is 3272 bytes of data
				let asn1 = UnsafeMutablePointer<UInt8>.allocate(capacity: 3500)
				let readLength = BIO_read(asn1Bio, asn1, 3500)
				let pemData = Data(bytes: asn1, count: Int(readLength))
                #if swift(>=4.1)
                asn1.deallocate()
                #else
                asn1.deallocate(capacity: 3500)
                #endif
				guard let pemString = String(data: pemData, encoding: .utf8) else {
					throw Error(code: ERR_INIT_PK, reason: "Couldn't utf8 decode pemString")
				}
				if !stripped {
					return pemString
				} else {
					let derString = try CryptorRSA.base64String(for: pemString)
					guard let derData = Data(base64Encoded: derString) else {
						throw Error(code: ERR_INIT_PK, reason: "Couldn't read PEM String")
					}
					let strippedDer = try CryptorRSA.stripX509CertificateHeader(for: derData)
					let pkcs1PEM = CryptorRSA.convertDerToPem(from: strippedDer, type: keyType)
					return pkcs1PEM
				}
			}
		#endif
	}
	// MARK: -
	
	///
	/// Public Key - Represents public key data.
	///
	public class PublicKey: RSAKey {
		
		/// MARK: Statics
		
		/// Regular expression for the PK using the begin and end markers.
		static let publicKeyRegex: NSRegularExpression? = {
			
			let publicKeyRegex = "(\(CryptorRSA.PK_BEGIN_MARKER).+?\(CryptorRSA.PK_END_MARKER))"
			return try? NSRegularExpression(pattern: publicKeyRegex, options: .dotMatchesLineSeparators)
		}()
		
		// MARK: -- Static Functions
		
		///
		/// Takes an input string, scans for public key sections, and then returns a Key for any valid keys found
		/// - This method scans the file for public key armor - if no keys are found, an empty array is returned
		/// - Each public key block found is "parsed" by `publicKeyFromPEMString()`
		/// - should that method throw, the error is _swallowed_ and not rethrown
		///
		/// - Parameters:
		///		- pemString: 		The string to use to parse out values
		///
		/// - Returns: 				An array of `PublicKey` objects containing just public keys.
		///
		public static func publicKeys(withPEM pemString: String) -> [PublicKey] {
			
			// If our regexp isn't valid, or the input string is empty, we can't move forward…
			guard let publicKeyRegexp = publicKeyRegex, pemString.count > 0 else {
				return []
			}
			
			let all = NSRange(
				location: 0,
				length: pemString.count
			)
			
			let matches = publicKeyRegexp.matches(
				in: pemString,
				options: NSRegularExpression.MatchingOptions(rawValue: 0),
				range: all
			)
			
			#if swift(>=4.1)
			
				let keys = matches.compactMap { result -> PublicKey? in
				
					let match = result.range(at: 1)
					let start = pemString.index(pemString.startIndex, offsetBy: match.location)
					let end = pemString.index(start, offsetBy: match.length)
					
					let range = start..<end
					
					let thisKey = pemString[range]
					
					return try? CryptorRSA.createPublicKey(withPEM: String(thisKey))
				}
			
			#else
			
				let keys = matches.flatMap { result -> PublicKey? in
			
					let match = result.range(at: 1)
					let start = pemString.index(pemString.startIndex, offsetBy: match.location)
					let end = pemString.index(start, offsetBy: match.length)
			
					let range = start..<end
			
					let thisKey = pemString[range]
			
					return try? CryptorRSA.createPublicKey(withPEM: String(thisKey))
				}
			
			#endif
			
			return keys
		}
		
		// MARK: -- Initializers
		
		///
		/// Create a public key using key data.
		///
		/// - Parameters:
		///		- data: 			Key data
		///
		/// - Returns:				New `PublicKey` instance.
		///
		public init(with data: Data) throws {
			try super.init(with: data, type: .publicType)
		}
		
		///
		/// Create a key using a native key.
		///
		/// - Parameters:
		///		- nativeKey:		Native key representation.
		///
		/// - Returns:				New `PublicKey` instance.
		///
		public init(with nativeKey: NativeKey) {
			
			super.init(with: nativeKey, type: .publicType)
		}

		#if os(Linux) && !swift(>=4.1)
		
			///
			/// Create a key using a native key.
			///
			/// - Parameters:
			///		- nativeKey:		Pointer to RSA key structure.
			///
			/// - Returns:				New `RSAKey` instance.
			///
			public init(with nativeKey: UnsafeMutablePointer<EVP_PKEY>) {
				
				super.init(with: nativeKey, type: .publicType)
			}
		
		#endif
	}
	
	// MARK: -
	
	///
	/// Private Key - Represents private key data.
	///
	public class PrivateKey: RSAKey {
		
		// MARK: -- Initializers
		
		///
		/// Create a private key using key data.
		///
		/// - Parameters:
		///		- data: 			Key data
		///
		/// - Returns:				New `PrivateKey` instance.
		///
		public init(with data: Data) throws {
			try super.init(with: data, type: .privateType)
		}
		
		///
		/// Create a key using a native key.
		///
		/// - Parameters:
		///		- nativeKey:		Native key representation.
		///
		/// - Returns:				New `PrivateKey` instance.
		///
		public init(with nativeKey: NativeKey) {
			
			super.init(with: nativeKey, type: .privateType)
		}
	}
}
