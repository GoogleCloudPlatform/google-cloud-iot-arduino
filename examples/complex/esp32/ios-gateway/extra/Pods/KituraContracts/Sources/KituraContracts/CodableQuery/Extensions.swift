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

/// Codable String Conversion Extension.
extension String {

    /// Converts the given String to an Int?.
    public var int: Int? {
        return Int(self)
    }

    /// Converts the given String to a Int8?.
    public var int8: Int8? {
        return Int8(self)
    }

    /// Converts the given String to a Int16?.
    public var int16: Int16? {
        return Int16(self)
    }

    /// Converts the given String to a Int32?.
    public var int32: Int32? {
        return Int32(self)
    }

    /// Converts the given String to a Int64?.
    public var int64: Int64? {
        return Int64(self)
    }

    /// Converts the given String to a UInt?.
    public var uInt: UInt? {
        return UInt(self)
    }

    /// Converts the given String to a UInt8?.
    public var uInt8: UInt8? {
        return UInt8(self)
    }

    /// Converts the given String to a UInt16?.
    public var uInt16: UInt16? {
        return UInt16(self)
    }

    /// Converts the given String to a UInt32?.
    public var uInt32: UInt32? {
        return UInt32(self)
    }

    /// Converts the given String to a UInt64?.
    public var uInt64: UInt64? {
        return UInt64(self)
    }

    /// Converts the given String to a Float?.
    public var float: Float? {
        return Float(self)
    }

    /// Converts the given String to a Double?.
    public var double: Double? {
        return Double(self)
    }

    /// Converts the given String to a Bool?.
    public var boolean: Bool? {
        return !self.isEmpty ? Bool(self) : false
    }

    /// Converts the given String to a String.
    public var string: String {
        return self
    }

    /// Converts the given String to an [Int]?.
    public var intArray: [Int]? {
        return decodeArray(Int.self)
    }

    /// Converts the given String to an [Int8]?.
    public var int8Array: [Int8]? {
        return decodeArray(Int8.self)
    }

    /// Converts the given String to an [Int16]?.
    public var int16Array: [Int16]? {
        return decodeArray(Int16.self)
    }

    /// Converts the given String to an [Int32]?.
    public var int32Array: [Int32]? {
        return decodeArray(Int32.self)
    }

    /// Converts the given String to an [Int64]?.
    public var int64Array: [Int64]? {
        return decodeArray(Int64.self)
    }

    /// Converts the given String to an [UInt]?.
    public var uIntArray: [UInt]? {
        return decodeArray(UInt.self)
    }

    /// Converts the given String to an [UInt8]?.
    public var uInt8Array: [UInt8]? {
        return decodeArray(UInt8.self)
    }

    /// Converts the given String to an [UInt16]?.
    public var uInt16Array: [UInt16]? {
        return decodeArray(UInt16.self)
    }

    /// Converts the given String to an [UInt32]?.
    public var uInt32Array: [UInt32]? {
        return decodeArray(UInt32.self)
    }

    /// Converts the given String to an [UInt64]?.
    public var uInt64Array: [UInt64]? {
        return decodeArray(UInt64.self)
    }

    /// Converts the given String to a [Float]?.
    public var floatArray: [Float]? {
        return decodeArray(Float.self)
    }

    /// Converts the given String to a [Double]?.
    public var doubleArray: [Double]? {
        return decodeArray(Double.self)
    }

    /// Converts the given String to a [Bool]?.
    public var booleanArray: [Bool]? {
        return decodeArray(Bool.self)
    }

    /// Converts the given String to a [String].
    public var stringArray: [String] {
        let strs: [String] = self.components(separatedBy: ",")
        return strs
    }

    /**
    Method used to decode a string into the given type T.
    
    - Parameter type: The Decodable type to convert the string into.
    - Returns: The Date? object. Some on success / nil on failure.
    */
    public func decodable<T: Decodable>(_ type: T.Type) -> T? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        let obj: T? = try? JSONDecoder().decode(type, from: data)
        return obj
    }

    /**
    Converts the given String to a Date?.
    
    - Parameter formatter: The designated DateFormatter to convert the string with.
    - Returns: The Date? object. Some on success / nil on failure.
    */
    public func date(_ formatter: DateFormatter) -> Date? {
        return formatter.date(from: self)
    }

    /**
    Converts the given String to a [Date]?.

    - Parameter formatter: The designated DateFormatter to convert the string with.
    - Returns: The [Date]? object. Some on success / nil on failure.
    */
    public func dateArray(_ formatter: DateFormatter) -> [Date]? {
        let strs: [String] = self.components(separatedBy: ",")
        let dates = strs.map { formatter.date(from: $0) }.filter { $0 != nil }.map { $0! }
        if dates.count == strs.count {
            return dates
        }
        return nil
    }

    /**
    Converts the given String to a [Date]? object using the dateDecodingStrategy supplied.
    
    - Parameter formatter: The designated `DateFormatter` to convert the string with.
    - Parameter decoderStrategy: The `JSON.dateDecodingStrategy` that should be used to decode the specifed Date.  Default is set to .formatted with default dateFormatter.
    - Parameter decoder: The `Decoder` parameter is only used for the custom strategy.
    - Returns: The [Date]? object. Some on success / nil on failure.
    */
    public func dateArray(decoderStrategy: JSONDecoder.DateDecodingStrategy = .formatted(Coder.defaultDateFormatter), decoder: Decoder?=nil) -> [Date]? {

        switch decoderStrategy {
        case .formatted(let formatter):
            let strs: [String] = self.components(separatedBy: ",")
            let dates = strs.map { formatter.date(from: $0) }.filter { $0 != nil }.map { $0! }
            if dates.count == strs.count {
                return dates
            }
            return nil
        case .deferredToDate:
            let strs: [String] = self.components(separatedBy: ",")
            #if swift(>=4.1)
                let dbs = strs.compactMap(Double.init)
            #else
                let dbs = strs.flatMap(Double.init)
            #endif
            let dates = dbs.map { Date(timeIntervalSinceReferenceDate: $0) }
            if dates.count == dbs.count {
                return dates
            }
            return nil
        case .secondsSince1970:
            let strs: [String] = self.components(separatedBy: ",")
            #if swift(>=4.1)
                let dbs = strs.compactMap(Double.init)
            #else
                let dbs = strs.flatMap(Double.init)
            #endif
            let dates = dbs.map { Date(timeIntervalSince1970: $0) }
            if dates.count == dbs.count {
                return dates
            }
            return nil
        case .millisecondsSince1970:
            let strs: [String] = self.components(separatedBy: ",")
            #if swift(>=4.1)
                let dbs = strs.compactMap(Double.init)
            #else
                let dbs = strs.flatMap(Double.init)
            #endif
            let dates = dbs.map { Date(timeIntervalSince1970: ($0)/1000) }
            if dates.count == dbs.count {
                return dates
            }
            return nil
        case .iso8601:
            let strs: [String] = self.components(separatedBy: ",")
            if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                let dates = strs.map { _iso8601Formatter.date(from: $0) }
                if dates.count == strs.count {
                    return dates as? [Date]
                }
                return nil
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }
        case .custom(let closure):
            var dateArray: [Date] = []
            guard let decoder = decoder else {return dateArray}
            var fieldValueArray = self.split(separator: ",")
                for _ in fieldValueArray {
                    // Call closure to decode value
                    guard let date = try? closure(decoder) else {
                        return nil
                    }
                    dateArray.append(date)
                    // Delete from array after use
                    fieldValueArray.removeFirst()
                }
            return dateArray
        #if swift(>=5) && !os(Linux)
        @unknown default:
            Log.error("Decoding strategy not found")
            fatalError()
        #endif
        }
    }
    /// Helper Method to decode a string to an LosslessStringConvertible array types.
    private func decodeArray<T: LosslessStringConvertible>(_ type: T.Type) -> [T]? {
        let strs: [String] = self.components(separatedBy: ",")
        let values: [T] = strs.map { T($0) }.filter { $0 != nil }.map { $0! }
        return values.count == strs.count ? values : nil
    }
    
    /// Parses percent encoded string into query parameters with comma-separated
    /// values.
    var urlDecodedFieldValuePairs: [String: String] {
        var result: [String: String] = [:]
        for item in self.components(separatedBy: "&") {
            let (key, value) = item.keyAndDecodedValue
            if let value = value {
                // If value already exists for this key, append it
                if let existingValue = result[key] {
                    result[key] = "\(existingValue),\(value)"
                }
                else {
                    result[key] = value
                }
            }
        }
        return result
    }
    
    /// Splits a URL-encoded key and value pair (e.g. "foo=bar") into a tuple
    /// with corresponding "key" and "value" values, with the value being URL
    /// unencoded.
    var keyAndDecodedValue: (key: String, value: String?) {
        guard let range = self.range(of: "=") else {
            return (key: self, value: nil)
        }
        let key = String(self[..<range.lowerBound])
        let value = String(self[range.upperBound...])

        let valueReplacingPlus = value.replacingOccurrences(of: "+", with: " ")
        let decodedValue = valueReplacingPlus.removingPercentEncoding
        if decodedValue == nil {
            Log.warning("Unable to decode query parameter \(key) (coded value: \(valueReplacingPlus)")
        }
        return (key: key, value: decodedValue ?? valueReplacingPlus)
    }
}

// ISO8601 Formatter used for formatting ISO8601 dates.
@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
var _iso8601Formatter: ISO8601DateFormatter = {
let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
return formatter
}()

enum DateError: Error {
    case unknownStrategy
}

extension DateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknownStrategy:
            return("Date encoding or decoding strategy not known.")
        }
    }
}
