//
//  Random.swift
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

public typealias RNGStatus = Status

///
/// Generates buffers of random bytes.
///
public class Random {

    ///
    /// Wraps native call.
    ///
    /// - Note: CCRNGStatus is typealiased to CCStatus but this routine can only return kCCSuccess or kCCRNGFailure
    ///
    /// - Parameter bytes: A pointer to the buffer that will receive the bytes
	///
    /// - Returns: `.success` or `.rngFailure` as appropriate.
    ///
	public class func generate(bytes: UnsafeMutablePointer<UInt8>, byteCount: Int) -> RNGStatus {
		
		#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	        let statusCode = CCRandomGenerateBytes(bytes, byteCount)
    	    guard let status = Status(rawValue: statusCode) else {
        	    fatalError("CCRandomGenerateBytes returned unexpected status code: \(statusCode)")
	        }
    	    return status
		#elseif os(Linux)
			let statusCode = RAND_bytes(bytes, Int32(byteCount))
			if statusCode != 1 {
				
				let errCode = ERR_get_error()
				return Status.rngFailure(errCode)
			}
			return Status.success
		#endif
    }
	
    ///
    ///	Generates an array of random bytes.
    ///
    /// - Parameter bytesCount: Number of random bytes to generate
	///
    /// - Returns: an array of random bytes
	///
    /// - Throws: `.success` or an `.rngFailure` on failure
	///
	public class func generate(byteCount: Int) throws -> [UInt8] {
		
        guard byteCount > 0 else {
			throw RNGStatus.paramError
		}
        
		var bytes = Array(repeating: UInt8(0), count:byteCount)
        let status = generate(bytes: &bytes, byteCount: byteCount)
		
		if status != .success {
			throw status
		}
		
        return bytes
    }
    
    ///
	///	A version of generateBytes that always throws an error.
    ///
	///	Use it to test that code handles this.
    ///
    /// - Parameter bytesCount: Number of random bytes to generate
	///
    /// - Returns: An array of random bytes
	///
	public class func generateBytesThrow(byteCount: Int) throws -> [UInt8] {
		
		if byteCount <= 0 {
			
            fatalError("generate: byteCount must be positve and non-zero")
        }
		var bytes: [UInt8] = Array(repeating: UInt8(0), count:byteCount)
        let status = generate(bytes: &bytes, byteCount: byteCount)
        throw status
        //return bytes
    }
}
