/*
 * Copyright IBM Corporation 2017
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
 */

import Foundation
import LoggerAPI

/**
 Query Parameter Decoder decodes a `[String: String]` object to a `Decodable` object instance. The decode function takes the `Decodable` object as a parameter to decode the dictionary into.
 
 ### Usage Example: ###
 ````swift
 let dict = ["intField": "23", "stringField": "a string", "intArray": "1,2,3", "dateField": "2017-10-31T16:15:56+0000", "optionalDateField": "2017-10-31T16:15:56+0000", "nested": "{\"nestedIntField\":333,\"nestedStringField\":\"nested string\"}" ]
 
 guard let query = try? QueryDecoder(dictionary: dict).decode(MyQuery.self) else {
     print("Failed to decode query to MyQuery Object")
     return
 }
 ````
 
 ### Decoding Empty Values:
 When an HTML form is sent with an empty or unchecked field, the corresponding key/value pair is sent with an empty value (i.e. `&key1=&key2=`).
 The corresponding mapping to Swift types performed by `QueryDecoder` is as follows:
 - Any Optional type (including `String?`) defaults to `nil`
 - Non-optional `String` successfully decodes to `""`
 - Non-optional `Bool` decodes to `false`
 - All other non-optional types throw a decoding error
 */
public class QueryDecoder: Coder, Decoder, BodyDecoder {
    
    /**
     The coding key path.
     
     ### Usage Example: ###
     ````swift
     let fieldName = Coder.getFieldName(from: codingPath)
     ````
     */
    public var codingPath: [CodingKey] = []

    /**
     The coding user info key.
     */
    public var userInfo: [CodingUserInfoKey : Any] = [:]

    /**
     A `[String: String]` dictionary.
     */
    public var dictionary: [String : String]


     // A `JSONDecoder.DateDecodingStrategy` date decoder used to determine what strategy
     // to use when decoding the specific date.
    private var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy
    /**
     Initializer with an empty dictionary for decoding from Data.
     */
    public override init () {
        self.dateDecodingStrategy = .formatted(Coder.defaultDateFormatter)
        self.dictionary = [:]
        super.init()
    }
    /**
     Initializer with a `[String : String]` dictionary.
     */
    public init(dictionary: [String : String]) {
        self.dateDecodingStrategy = .formatted(Coder.defaultDateFormatter)
        self.dictionary = dictionary
        super.init()
    }
    /**
     Decode URL encoded data by mapping to its Decodable object representation.
     
     - Parameter type: The Decodable type to the Data will be decoded as.
     - Parameter from: The Data to be decoded as the Decodable type.
     
     ### Usage Example: ###
     ````swift
     guard let query = try? QueryDecoder().decode(MyQuery.self, from queryData) else {
        print("Failed to decode query to MyQuery Object")
        return
     }
     ````
     */
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        guard let urlString = String(data: data, encoding: .utf8) else {
            throw RequestError.unprocessableEntity
        }
        let decoder = QueryDecoder(dictionary: urlString.urlDecodedFieldValuePairs)
        decoder.dateDecodingStrategy = dateDecodingStrategy
        if let Q = T.self as? QueryParams.Type {
            decoder.dateDecodingStrategy = Q.dateDecodingStrategy
        }
        return try T(from: decoder)
    }

    /**
     Decodes a `[String: String]` mapping to its Decodable object representation.
     
     - Parameter value: The Decodable object to decode the dictionary into.
     
     ### Usage Example: ###
     ````swift
     guard let query = try? QueryDecoder(dictionary: expectedDict).decode(MyQuery.self) else {
         print("Failed to decode query to MyQuery Object")
         return
     }
     ````
     */
    public func decode<T: Decodable>(_ type: T.Type) throws -> T {
        if let Q = T.self as? QueryParams.Type {
            dateDecodingStrategy = Q.dateDecodingStrategy
        }
        let fieldName = Coder.getFieldName(from: codingPath)
        let fieldValue = dictionary[fieldName]
        Log.verbose("fieldName: \(fieldName), fieldValue: \(String(describing: fieldValue))")

        switch type {
        /// Bool
        case is Bool.Type:
            return try decodeType(fieldValue?.boolean, to: T.self)
        /// Ints
        case is Int.Type:
            return try decodeType(fieldValue?.int, to: T.self)
        case is Int8.Type:
            return try decodeType(fieldValue?.int8, to: T.self)
        case is Int16.Type:
            return try decodeType(fieldValue?.int16, to: T.self)
        case is Int32.Type:
            return try decodeType(fieldValue?.int32, to: T.self)
        case is Int64.Type:
            return try decodeType(fieldValue?.int64, to: T.self)
        /// Int Arrays
        case is [Int].Type:
            return try decodeType(fieldValue?.intArray, to: T.self)
        case is [Int8].Type:
            return try decodeType(fieldValue?.int8Array, to: T.self)
        case is [Int16].Type:
            return try decodeType(fieldValue?.int16Array, to: T.self)
        case is [Int32].Type:
            return try decodeType(fieldValue?.int32Array, to: T.self)
        case is [Int64].Type:
            return try decodeType(fieldValue?.int64Array, to: T.self)
        /// UInts
        case is UInt.Type:
            return try decodeType(fieldValue?.uInt, to: T.self)
        case is UInt8.Type:
            return try decodeType(fieldValue?.uInt8, to: T.self)
        case is UInt16.Type:
            return try decodeType(fieldValue?.uInt16, to: T.self)
        case is UInt32.Type:
            return try decodeType(fieldValue?.uInt32, to: T.self)
        case is UInt64.Type:
            return try decodeType(fieldValue?.uInt64, to: T.self)
        /// UInt Arrays
        case is [UInt].Type:
            return try decodeType(fieldValue?.uIntArray, to: T.self)
        case is [UInt8].Type:
            return try decodeType(fieldValue?.uInt8Array, to: T.self)
        case is [UInt16].Type:
            return try decodeType(fieldValue?.uInt16Array, to: T.self)
        case is [UInt32].Type:
            return try decodeType(fieldValue?.uInt32Array, to: T.self)
        case is [UInt64].Type:
            return try decodeType(fieldValue?.uInt64Array, to: T.self)
        /// Floats
        case is Float.Type:
            return try decodeType(fieldValue?.float, to: T.self)
        case is [Float].Type:
            return try decodeType(fieldValue?.floatArray, to: T.self)
        /// Doubles
        case is Double.Type:
            return try decodeType(fieldValue?.double, to: T.self)
        case is [Double].Type:
            return try decodeType(fieldValue?.doubleArray, to: T.self)
        /// Dates
        case is Date.Type:
            switch dateDecodingStrategy {
            case .deferredToDate:
                guard let doubleValue = fieldValue?.double else {return try decodeType(fieldValue, to: T.self)}
                return try decodeType(Date(timeIntervalSinceReferenceDate: (doubleValue)), to: T.self)
            case .secondsSince1970:
                guard let doubleValue = fieldValue?.double else {return try decodeType(fieldValue, to: T.self)}
                return try decodeType(Date(timeIntervalSince1970: (doubleValue)), to: T.self)
            case .millisecondsSince1970:
                guard let doubleValue = fieldValue?.double else {return try decodeType(fieldValue, to: T.self)}
                return try decodeType(Date(timeIntervalSince1970: (doubleValue)), to: T.self)
            case .iso8601:
                if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                    guard let stringValue = fieldValue?.string else {return try decodeType(fieldValue, to: T.self)}
                        guard let date = _iso8601Formatter.date(from: stringValue) else {
                            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected date string to be ISO8601-formatted."))
                        }
                        return try decodeType(date, to: T.self)
                } else {
                    fatalError("ISO8601DateFormatter is unavailable on this platform.")
                }
            case .formatted(let formatted):
                return try decodeType(fieldValue?.date(formatted), to: T.self)
            case .custom(let closure):
                return try decodeType(closure(self), to: T.self)
            #if swift(>=5) && !os(Linux)
            @unknown default:
                throw DateError.unknownStrategy
            #endif
            }
        case is [Date].Type:
            switch dateDecodingStrategy {
            case .deferredToDate:
                return try decodeType(fieldValue?.dateArray(decoderStrategy: .deferredToDate), to: T.self)
            case .secondsSince1970:
                return try decodeType(fieldValue?.dateArray(decoderStrategy: .secondsSince1970), to: T.self)
            case .millisecondsSince1970:
                return try decodeType(fieldValue?.dateArray(decoderStrategy: .millisecondsSince1970), to: T.self)
            case .iso8601:
                if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                    return try decodeType(fieldValue?.dateArray(decoderStrategy: .iso8601), to: T.self)
                } else {
                    fatalError("ISO8601DateFormatter is unavailable on this platform.")
                }
            case .formatted(let formatter):
                return try decodeType(fieldValue?.dateArray(formatter), to: T.self)
            case .custom(let closure):
                return try decodeType(fieldValue?.dateArray(decoderStrategy: .custom(closure), decoder: self), to: T.self)
            #if swift(>=5) && !os(Linux)
            @unknown default:
                throw DateError.unknownStrategy
            #endif
            }
        /// Strings
        case is String.Type:
            return try decodeType(fieldValue?.string, to: T.self)
        case is [String].Type:
            return try decodeType(fieldValue?.stringArray, to: T.self)
        case is Operation.Type:
            if let oType = type as? Operation.Type,
               let value = fieldValue?.string {
              let result = try oType.init(string: value)
              if let castedValue = result as? T {
                return castedValue
              }
            }
            return try decodeType(fieldValue?.decodable(T.self), to: T.self)
        case is Ordering.Type:
            if let oType = type as? Ordering.Type,
               let value = fieldValue?.string {
              let result = try oType.init(string: value)
              if let castedValue = result as? T {
                return castedValue
              }
            }
            return try decodeType(fieldValue?.decodable(T.self), to: T.self)
        case is Pagination.Type:
            if let oType = type as? Pagination.Type,
               let value = fieldValue?.string {
              let result = try oType.init(string: value)
              if let castedValue = result as? T {
                return castedValue
              }
            }
            return try decodeType(fieldValue?.decodable(T.self), to: T.self)
        default:
            Log.verbose("Decoding Custom Type: \(T.Type.self)")
            if fieldName.isEmpty {
                return try T(from: self)
            } else {
                // Processing an instance member of the class/struct
                return try decodeType(fieldValue?.decodable(T.self), to: T.self)
            }
        }
    }

    /**
     Returns a keyed decoding container based on the key type.

     ### Usage Example: ###
     ````swift
     decoder.container(keyedBy: keyType)
     ````
     */
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(KeyedContainer<Key>(decoder: self))
    }

    /**
     Returns an unkeyed decoding container.
     
     ### Usage Example: ###
     ````swift
     decoder.unkeyedContainer()
     ````
     */
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return UnkeyedContainer(decoder: self)
    }

    /**
     Returns a single value decoding container based on the key type.
     
     ### Usage Example: ###
     ````swift
     decoder.singleValueContainer()
     ````
     */
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return UnkeyedContainer(decoder: self)
    }

    private func decodeType<S: Decodable, T: Decodable>(_ object: S, to type: T.Type) throws -> T {
        if let values = object as? T {
            return values
        } else {
            throw decodingError()
        }
    }

    private func decodingError() -> DecodingError {
        let fieldName = Coder.getFieldName(from: codingPath)
        let errorMsg = "Could not process field named '\(fieldName)'."
        Log.error(errorMsg)
        let errorCtx = DecodingError.Context(codingPath: codingPath, debugDescription: errorMsg)
        return DecodingError.dataCorrupted(errorCtx)
    }

    private struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        var decoder: QueryDecoder

        var codingPath: [CodingKey] { return [] }

        var allKeys: [Key] { return [] }

        func contains(_ key: Key) -> Bool {
          return decoder.dictionary[key.stringValue] != nil
        }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
          self.decoder.codingPath.append(key)
          defer { self.decoder.codingPath.removeLast() }
          return try decoder.decode(T.self)
        }

        // If it is not in the dictionary or it is a empty string it should be nil
        func decodeNil(forKey key: Key) throws -> Bool {
          return decoder.dictionary[key.stringValue]?.isEmpty ??  true
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return try decoder.container(keyedBy: type)
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            return try decoder.unkeyedContainer()
        }

        func superDecoder() throws -> Decoder {
            return decoder
        }

        func superDecoder(forKey key: Key) throws -> Decoder {
            return decoder
        }
    }

    private struct UnkeyedContainer: UnkeyedDecodingContainer, SingleValueDecodingContainer {
        var decoder: QueryDecoder

        var codingPath: [CodingKey] { return [] }

        var count: Int? { return nil }

        var currentIndex: Int { return 0 }

        var isAtEnd: Bool { return false }

        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            return try decoder.decode(type)
        }

        func decodeNil() -> Bool {
            return true
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return try decoder.container(keyedBy: type)
        }

        func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            return self
        }

        func superDecoder() throws -> Decoder {
            return decoder
        }
    }

}
