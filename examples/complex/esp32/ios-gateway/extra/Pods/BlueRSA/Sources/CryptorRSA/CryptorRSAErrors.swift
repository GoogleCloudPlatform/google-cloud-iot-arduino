//
//  CryptorRSAErrors.swift
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

import Foundation

// MARK: -

@available(macOS 10.12, iOS 10.3, watchOS 3.3, tvOS 12.0, *)
extension CryptorRSA {
	
	// MARK: Constants
	
	// MARK: -- Generic
	
	// MARK: -- Errors: Domain and Codes
	
	public static let ERR_DOMAIN						= "com.ibm.oss.CryptorRSA.ErrorDomain"
	
	public static let ERR_ADD_KEY						= -9999
	public static let ERR_DELETE_KEY					= -9998
	public static let ERR_STRIP_PK_HEADER				= -9997
	public static let ERR_INIT_PK						= -9996
	public static let ERR_BASE64_PEM_DATA				= -9995
	public static let ERR_STRING_ENCODING				= -9994
	public static let ERR_KEY_NOT_PUBLIC				= -9993
	public static let ERR_KEY_NOT_PRIVATE				= -9992
	public static let ERR_NOT_ENCRYPTED					= -9991
	public static let ERR_ENCRYPTION_FAILED				= -9990
	public static let ERR_NOT_SIGNED_DATA				= -9989
	public static let ERR_NOT_PLAINTEXT					= -9988
	public static let ERR_DECRYPTION_FAILED				= -9997
	public static let ERR_SIGNING_FAILED				= -9986
	public static let ERR_VERIFICATION_FAILED			= -9985
	public static let ERR_CREATE_CERT_FAILED			= -9984
	public static let ERR_EXTRACT_PUBLIC_KEY_FAILED		= -9983
	public static let ERR_EXTRACT_PRIVATE_KEY_FAILED	= -9983
	public static let ERR_NOT_IMPLEMENTED				= -9982
    
	// MARK: -- Error
	
	///
	/// `RSA` specific error structure.
	///
	public struct Error: Swift.Error, CustomStringConvertible {
		
		// MARK: -- Public Properties
		
		///
		/// The error domain.
		///
		public let domain: String = ERR_DOMAIN
		
		///
		/// The error code: **see constants above for possible errors** (Readonly)
		///
		public internal(set) var errorCode: Int32
		
		///
		/// The reason for the error **(if available)** (Readonly)
		///
		public internal(set) var errorReason: String?
		
		///
		/// Returns a string description of the error. (Readonly)
		///
		public var description: String {
			
			let reason: String = self.errorReason ?? "Reason: Unavailable"
			return "Error code: \(self.errorCode)(0x\(String(self.errorCode, radix: 16, uppercase: true))), \(reason)"
		}
		
		// MARK: -- Public Functions
		
		///
		/// Initializes an Error Instance
		///
		/// - Parameters:
		///		- code:		Error code
		/// 	- reason:	Optional Error Reason
		///
		/// - Returns: Error instance
		///
		public init(code: Int, reason: String?) {
			
			self.errorCode = Int32(code)
			self.errorReason = reason
		}
		
	}
}
