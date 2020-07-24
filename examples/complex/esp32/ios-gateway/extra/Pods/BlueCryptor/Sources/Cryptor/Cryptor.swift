//
//  Cryptor.swift
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

///
///	Encrypts or decrypts, accumulating result.
///
///	Useful for small in-memory buffers.
///
/// For large files or network streams use StreamCryptor.
///
public class Cryptor: StreamCryptor, Updatable {

	/// Internal accumulator for gathering data from the update() and final() functions.
    var accumulator: [UInt8] = []
	
    ///
	///	Retrieves the encrypted or decrypted data.
	///
	///- Returns: the encrypted or decrypted data or nil if an error occured.
	///
	public func final() -> [UInt8]? {
		
        let byteCount = Int(self.getOutputLength(inputByteCount: 0, isFinal: true))
		var dataOut = Array<UInt8>(repeating: 0, count:byteCount)
        var dataOutMoved = 0
        (dataOutMoved, self.status) = final(byteArrayOut: &dataOut)
        if self.status != .success {
   	        return nil
       	}
        accumulator += dataOut[0..<Int(dataOutMoved)]
        return accumulator
    }
    
    ///
	///	Upates the accumulated encrypted/decrypted data with the contents
	///	of a raw byte buffer.
	///
	///	It is not envisaged the users of the framework will need to call this directly.
	///
	/// - Returns: this Cryptor object or nil if an error occurs (for optional chaining)
    ///
	public func update(from buffer: UnsafeRawPointer, byteCount: Int) -> Self? {
    
        let outputLength = Int(self.getOutputLength(inputByteCount: byteCount, isFinal: false))
		var dataOut = Array<UInt8>(repeating: 0, count:outputLength)
        var dataOutMoved = 0
        _ = update(bufferIn: buffer, byteCountIn: byteCount, bufferOut: &dataOut, byteCapacityOut: dataOut.count, byteCountOut: &dataOutMoved)
		if self.status != .success {
			return nil
		}
        accumulator += dataOut[0..<Int(dataOutMoved)]
        return self
    }

}
