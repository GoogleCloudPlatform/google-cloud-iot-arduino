/**
 * Copyright IBM Corporation 2019
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation

/// A struct representing the different errors that can be thrown by BlueECC.
public struct ECError: Error, Equatable {
    
    /// A human readable description of the error.
    public let localizedDescription: String

    private let internalError: InternalError
    
    private enum InternalError {
        case invalidPEMString, unknownPEMHeader, failedBase64Encoding, failedASN1Decoding, unsupportedCurve, failedNativeKeyCreation, failedEvpInit, failedSigningAlgorithm, invalidRSLength, failedEncryptionAlgorithm, failedUTF8Decoding, failedDecryptionAlgorithm
    }
    
    /// Error thrown when an invalid PEM String used to initialize a key.
    public static let invalidPEMString = ECError(localizedDescription: "Input was not a valid PEM String", internalError: .invalidPEMString)
    
    /// Error thrown when the PEM header is not recognized.
    public static let unknownPEMHeader = ECError(localizedDescription: "Input PEM header was not recognized", internalError: .unknownPEMHeader)

    /// Error thrown when a String fails to be Base64 encoded.
    public static let failedBase64Encoding = ECError(localizedDescription: "Failed to base64 encode the String", internalError: .failedBase64Encoding)

    /// Error thrown when the ASN1 data could not be decoded to the expected structure.
    public static let failedASN1Decoding = ECError(localizedDescription: "ASN1 data could not be decoded to expected structure", internalError: .failedASN1Decoding)
    
    /// Error thrown when the key's object identifier is for a curve that is not supported.
    public static let unsupportedCurve = ECError(localizedDescription: "The key object identifier is for a non-supported curve", internalError: .unsupportedCurve)
    
    /// Error thrown when the key could not be converted to a native key (`SecKey` for Apple, `EC_KEY` for linux).
    public static let failedNativeKeyCreation = ECError(localizedDescription: "The key data could not be converted to a native key", internalError: .failedNativeKeyCreation)
    
    /// Error thrown when the encryption envelope fails to initialize.
    public static let failedEvpInit = ECError(localizedDescription: "Failed to initialize the signing envelope", internalError: .failedEvpInit)
        
    /// Error thrown when the signing algorithm could not create the signature.
    public static let failedSigningAlgorithm = ECError(localizedDescription: "Signing algorithm failed to create the signature", internalError: .failedSigningAlgorithm)
    
    /// Error thrown when the provided R and S Data was not a valid length.
    /// They must be the same length and either 32, 48 or 66 bytes (depending on the curve used).
    public static let invalidRSLength = ECError(localizedDescription: "The provided R and S values were not a valid length", internalError: .invalidRSLength)
    
    /// Error thrown when the encryption algorithm could not encrypt the plaintext.
    public static let failedEncryptionAlgorithm = ECError(localizedDescription: "Encryption algorithm failed to encrypt the data", internalError: .failedEncryptionAlgorithm)
    
    /// Error thrown when the decryption algorithm could not decrypt the encrypted Data.
    public static let failedDecryptionAlgorithm = ECError(localizedDescription: "Decryption algorithm failed to decrypt the data", internalError: .failedDecryptionAlgorithm)
    
    /// Error thrown when the Data could not be decoded into a UTF8 String.
    public static let failedUTF8Decoding = ECError(localizedDescription: "Data could not be decoded as a UTF8 String", internalError: .failedUTF8Decoding)
    
    /// Checks if ECSigningErrors are equal, required for Equatable protocol.
    public static func == (lhs: ECError, rhs: ECError) -> Bool {
        return lhs.internalError == rhs.internalError
    }
}
