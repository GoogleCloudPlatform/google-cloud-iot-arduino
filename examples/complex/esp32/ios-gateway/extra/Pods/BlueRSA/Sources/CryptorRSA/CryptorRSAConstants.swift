//
//  CryptorRSAConstants.swift
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
public extension CryptorRSA {
	
	// MARK: Constants
	
	// MARK: Certificate Suffixes
	
	/// X509 Certificate Extension
	static let CER_SUFFIX: String						= ".cer"
	
	/// PEM Suffix
	static let PEM_SUFFIX: String						= ".pem"
	
	/// DER Suffix
	static let DER_SUFFIX: String						= ".der"
	
	// MARK: PEM Certificate Markers
	
	/// PEM Begin Marker
	static let PEM_BEGIN_MARKER: String					= "-----BEGIN CERTIFICATE-----"

	/// PEM End Marker
	static let PEM_END_MARKER: String					= "-----END CERTIFICATE-----"
	
	// MARK: Public Key Markers

	/// PK Begin Marker
	static let PK_BEGIN_MARKER: String					= "-----BEGIN PUBLIC KEY-----"
	
	/// PK End Marker
	static let PK_END_MARKER: String					= "-----END PUBLIC KEY-----"
	
	// MARK: Private Key Markers
	
	/// SK Begin Marker
	static let SK_BEGIN_MARKER: String					= "-----BEGIN RSA PRIVATE KEY-----"
	
	/// SK End Marker
	static let SK_END_MARKER: String					= "-----END RSA PRIVATE KEY-----"
	
	// MARK: Generic Key Markers
	
	/// Generic Begin Marker
	static let GENERIC_BEGIN_MARKER: String				= "-----BEGIN"
	
	/// Generic End Marker
	static let GENERIC_END_MARKER: String				= "-----END"
	
}
