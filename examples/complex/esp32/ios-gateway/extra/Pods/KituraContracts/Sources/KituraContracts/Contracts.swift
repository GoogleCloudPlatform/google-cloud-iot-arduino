/**
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
 **/

 import Foundation

// MARK

/**
 An error representing a failed request.
 This definition is intended to be used by both the client side (e.g. KituraKit)
 and server side (e.g. Kitura) of the request (typically a HTTP REST request).

 ### Usage Example: ###

 In this example, the `RequestError` is used in a Kitura server Codable route handler to
 indicate the request has failed because the requested record was not found.
 ````swift
 router.get("/users") { (id: Int, respondWith: (User?, RequestError?) -> Void) in
     ...
     respondWith(nil, RequestError.notFound)
     ...
 }
 ````
 */
public struct RequestError: RawRepresentable, Equatable, Hashable, Comparable, Error, CustomStringConvertible {
    /**
    A typealias representing the type of error that has occurred.
    The range of error codes from 100 up to 599 are reserved for HTTP status codes.
    Custom error codes may be used and must not conflict with this range.
    */
    public typealias RawValue = Int

    /**
    Representation of the error body.
    May be a type-erased Codable object or a Data (in a particular format).
    */
    public enum ErrorBody {
        /// Codable object.
        case codable(Codable)
        /// Data object.
        case data(Data, BodyFormat)
    }

    // MARK: Creating a RequestError from a numeric code
    /**
    Creates an error representing the given error code.

     - parameter rawValue: An Int indicating an error code representing the type of error that has occurred.
    */
    public init(rawValue: Int) {
        self.rawValue = rawValue
        self.reason = "error_\(rawValue)"
    }

    /**
    Creates an error representing the given error code and reason string.

     - parameter rawValue: An Int indicating an error code representing the type of error that has occurred.
     - parameter reason: A human-readable description of the error code.
    */
    public init(rawValue: Int, reason: String) {
        self.rawValue = rawValue
        self.reason = reason
    }

    /**
    Creates an error representing the given base error, with a custom
    response body given as a Codable.

     - parameter base: A `RequestError` object.
     - parameter body: A representation of the error body - an object representing further details of the failure.
    */
    public init<Body: Codable>(_ base: RequestError, body: Body) {
        self.rawValue = base.rawValue
        self.reason = base.reason
        self.body = .codable(body)
        self.bodyDataEncoder = { format in
            switch format {
                case .json: return try JSONEncoder().encode(body)
                default: throw UnsupportedBodyFormatError(format)
            }
        }
    }

    /**
    Creates an error respresenting the given base error, with a custom
    response body given as Data and a BodyFormat.

     - parameter base: A `RequestError` object.
     - parameter bodyData: A `Data` object.
     - parameter format: A `BodyFormat` object used to check whether it is legal JSON.
     - throws: An `UnsupportedBodyFormatError` if the provided `BodyFormat`
             is not supported.
    */
    public init(_ base: RequestError, bodyData: Data, format: BodyFormat) throws {
        self.rawValue = base.rawValue
        self.reason = base.reason
        self.body = .data(bodyData, format)
        switch format {
            case .json: break
            default: throw UnsupportedBodyFormatError(format)
        }
    }

    // MARK: Accessing information about the error

    /**
    An error code representing the type of error that has occurred.
    The range of error codes from 100 up to 599 are reserved for HTTP status codes.
    Custom error codes may be used and must not conflict with this range.
    */
    public let rawValue: Int

    /**
    A human-readable description of the error code.
    */
    public let reason: String

    /**
     Representation of the error body - an object representing further
     details of the failure.

     The value may be:
     - `nil` if there is no body
     - a (type-erased) Codable object if the error was initialized with `init(_:body:)`
     - bytes of data and a signifier of the format in which they are stored (eg: JSON)
       if the error was initialized with `init(_:bodyData:format:)`

     ### Usage example: ###
     ````swift
     if let errorBody = error.body {
         switch error.body {
            case let .codable(body): ... // body is Codable
            case let .data(bytes, format): ... // bytes is Data, format is BodyFormat
         }
     }
     ````

     - Note: If you need a Codable representation and the body is data, you
             can call the `bodyAs(_:)` function to get the converted value.
     */
    public private(set) var body: ErrorBody? = nil

    // A closure used to hide the generic type of the Codable body
    // for later encoding to Data.
    private var bodyDataEncoder: ((BodyFormat) throws -> Data)? = nil

    /**
     Returns the Codable error body encoded into bytes in a given format (eg: JSON).

     This function should be used if the RequestError was created using
     `init(_:body:)`, otherwise it will return `nil`.

     - Note: This function is primarily intended for use by the Kitura Router so
             that it can encode and send a custom error body returned from
             a codable route.

     ### Usage Example: ###
     ````swift
     do {
         if let errorBodyData = try error.encodeBody(.json) {
             ...
         }
     } catch {
         // Handle the failure to encode
     }
     ````
     - parameter format: Describes the format that should be used
                 (for example: `BodyFormat.json`).
     - returns: The `Data` object or `nil` if there is no body, or if the
               error was not initialized with `init(_:body:)`.
     - throws: An `EncodingError` if the encoding fails.
     - throws: An `UnsupportedBodyFormatError` if the provided `BodyFormat`
              is not supported.
     */
    public func encodeBody(_ format: BodyFormat) throws -> Data? {
        guard case .codable? = body else { return nil }
        return try bodyDataEncoder?(format)
    }

    /**
     Returns the Data error body as the requested `Codable` type.

     This function should be used if the RequestError was created using
     `init(_:bodyData:format:)`, otherwise it will return `nil`.

     This function throws; you can use `bodyAs(_:)` instead if you want
     to ignore DecodingErrors.

     - Note: This function is primarily intended for use by users of KituraKit
             or similar client-side code that needs to convert a custom error
             response from `Data` to a `Codable` type.

     ### Usage Example: ###
     ````swift
     do {
         if let errorBody = try error.decodeBody(MyCodableType.self) {
             ...
         }
     } catch {
         // Handle failure to decode
     }
     ````
     - parameter type: The type of the value to decode from the body data
                 (for example: `MyCodableType.self`).
     - returns: The `Codable` object or `nil` if there is no body or if the
               error was not initialized with `init(_:bodyData:format:)`.
     - throws: A `DecodingError` if decoding fails.
     */
    public func decodeBody<Body: Codable>(_ type: Body.Type) throws -> Body? {
        guard case let .data(bodyData, format)? = body else { return nil }
        switch format {
            case .json: return try JSONDecoder().decode(type, from: bodyData)
            default: throw UnsupportedBodyFormatError(format)
        }
    }

    /**
     Returns the Data error body as the requested `Codable` type.

     This function should be used if the RequestError was created using
     `init(_:bodyData:format:)`, otherwise it will return `nil`.

     This function ignores DecodingErrors, and returns `nil` if decoding
     fails. If you want DecodingErrors to be thrown, use `decodeBody(_:)`
     instead.

     - Note: This function is primarily intended for use by users of KituraKit
             or similar client-side code that needs to convert a custom error
             response from `Data` to a `Codable` type.

     ### Usage Example: ###
     ````swift
     if let errorBody = error.bodyAs(MyCodableType.self) {
         ...
     }
     ````
     - parameter type: The type of the value to decode from the body data
                 (for example: `MyCodableType.self`).
     - returns: The `Codable` object or `nil` if there is no body, or if the
               error was not initialized with `init(_:bodyData:format:)`, or
               if decoding fails.
     */
    public func bodyAs<Body: Codable>(_ type: Body.Type) -> Body? {
        return (try? decodeBody(type)) ?? nil
    }

    // MARK: Comparing RequestErrors

    /**
    Returns a Boolean value indicating whether the value of the first argument is less than that of the second argument.
    */
    public static func < (lhs: RequestError, rhs: RequestError) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    /**
    Indicates whether two URLs are the same.
    */
    public static func == (lhs: RequestError, rhs: RequestError) -> Bool {
        return (lhs.rawValue == rhs.rawValue && lhs.reason == rhs.reason)
    }

    // MARK: Describing a RequestError

    /**
    A textual description of the RequestError instance containing the error code and reason.
    */
    public var description: String {
        return "\(rawValue) : \(reason)"
    }

    /**
    The computed hash value for the RequestError instance.
    */
    public var hashValue: Int {
        let str = reason + String(rawValue)
        return str.hashValue
    }
}

/**
 Extends `RequestError` to provide HTTP specific error code and reason values.
 */
extension RequestError {

    /**
    The HTTP status code for the error.
    This value should be a valid HTTP status code if inside the range 100 to 599,
    however, it may take a value outside that range when representing other types
    of error.
    */
    public var httpCode: Int {
        return rawValue
    }

    /**
    Creates an error representing a HTTP status code.
    - Parameter httpCode: A standard HTTP status code.
    */
    public init(httpCode: Int) {
        self.rawValue = httpCode
        self.reason = RequestError.reason(forHTTPCode: httpCode)
    }

    // MARK: Accessing constants representing HTTP status codes
    /// HTTP code 100 - Continue
    public static let `continue` = RequestError(httpCode: 100)
    /// HTTP code 101 - Switching Protocols
    public static let switchingProtocols = RequestError(httpCode: 101)
    /// HTTP code 200 - OK
    public static let ok = RequestError(httpCode: 200)
    /// HTTP code 201 - Created
    public static let created = RequestError(httpCode: 201)
    /// HTTP code 202 - Accepted
    public static let accepted = RequestError(httpCode: 202)
    /// HTTP code 203 - Non Authoritative Information
    public static let nonAuthoritativeInformation = RequestError(httpCode: 203)
    /// HTTP code 204 - No Content
    public static let noContent = RequestError(httpCode: 204)
    /// HTTP code 205 - Reset Content
    public static let resetContent = RequestError(httpCode: 205)
    /// HTTP code 206 - Partial Content
    public static let partialContent = RequestError(httpCode: 206)
    /// HTTP code 207 - Multi Status
    public static let multiStatus = RequestError(httpCode: 207)
    /// HTTP code 208 - Already Reported
    public static let alreadyReported = RequestError(httpCode: 208)
    /// HTTP code 226 - IM Used
    public static let imUsed = RequestError(httpCode: 226)
    /// HTTP code 300 - Multiple Choices
    public static let multipleChoices = RequestError(httpCode: 300)
    /// HTTP code 301 - Moved Permanently
    public static let movedPermanently = RequestError(httpCode: 301)
    /// HTTP code 302 - Found
    public static let found = RequestError(httpCode: 302)
    /// HTTP code 303 - See Other
    public static let seeOther = RequestError(httpCode: 303)
    /// HTTP code 304 - Not Modified
    public static let notModified = RequestError(httpCode: 304)
    /// HTTP code 305 - Use Proxy
    public static let useProxy = RequestError(httpCode: 305)
    /// HTTP code 307 - Temporary Redirect
    public static let temporaryRedirect = RequestError(httpCode: 307)
    /// HTTP code 308 - Permanent Redirect
    public static let permanentRedirect = RequestError(httpCode: 308)
    /// HTTP code 400 - Bad Request
    public static let badRequest = RequestError(httpCode: 400)
    /// HTTP code 401 - Unauthorized
    public static let unauthorized = RequestError(httpCode: 401)
    /// HTTP code 402 - Payment Required
    public static let paymentRequired = RequestError(httpCode: 402)
    /// HTTP code 403 - Forbidden
    public static let forbidden = RequestError(httpCode: 403)
    /// HTTP code 404 - Not Found
    public static let notFound = RequestError(httpCode: 404)
    /// HTTP code 405 - Method Not Allowed
    public static let methodNotAllowed = RequestError(httpCode: 405)
    /// HTTP code 406 - Not Acceptable
    public static let notAcceptable = RequestError(httpCode: 406)
    /// HTTP code 407 - Proxy Authentication Required
    public static let proxyAuthenticationRequired = RequestError(httpCode: 407)
    /// HTTP code 408 - Request Timeout
    public static let requestTimeout = RequestError(httpCode: 408)
    /// HTTP code 409 - Conflict
    public static let conflict = RequestError(httpCode: 409)
    /// HTTP code 410 - Gone
    public static let gone = RequestError(httpCode: 410)
    /// HTTP code 411 - Length Required
    public static let lengthRequired = RequestError(httpCode: 411)
    /// HTTP code 412 - Precondition Failed
    public static let preconditionFailed = RequestError(httpCode: 412)
    /// HTTP code 413 - Payload Too Large
    public static let payloadTooLarge = RequestError(httpCode: 413)
    /// HTTP code 414 - URI Too Long
    public static let uriTooLong = RequestError(httpCode: 414)
    /// HTTP code 415 - Unsupported Media Type
    public static let unsupportedMediaType = RequestError(httpCode: 415)
    /// HTTP code 416 - Range Not Satisfiable
    public static let rangeNotSatisfiable = RequestError(httpCode: 416)
    /// HTTP code 417 - Expectation Failed
    public static let expectationFailed = RequestError(httpCode: 417)
    /// HTTP code 421 - Misdirected Request
    public static let misdirectedRequest = RequestError(httpCode: 421)
    /// HTTP code 422 - Unprocessable Entity
    public static let unprocessableEntity = RequestError(httpCode: 422)
    /// HTTP code 423 - Locked
    public static let locked = RequestError(httpCode: 423)
    /// HTTP code 424 - Failed Dependency
    public static let failedDependency = RequestError(httpCode: 424)
    /// HTTP code 426 - Upgrade Required
    public static let upgradeRequired = RequestError(httpCode: 426)
    /// HTTP code 428 - Precondition Required
    public static let preconditionRequired = RequestError(httpCode: 428)
    /// HTTP code 429 - Too Many Requests
    public static let tooManyRequests = RequestError(httpCode: 429)
    /// HTTP code 431 - Request Header Fields Too Large
    public static let requestHeaderFieldsTooLarge = RequestError(httpCode: 431)
    /// HTTP code 451 - Unavailable For Legal Reasons
    public static let unavailableForLegalReasons = RequestError(httpCode: 451)
    /// HTTP code 500 - Internal Server Error
    public static let internalServerError = RequestError(httpCode: 500)
    /// HTTP code 501 - Not Implemented
    public static let notImplemented = RequestError(httpCode: 501)
    /// HTTP code 502 - Bad Gateway
    public static let badGateway = RequestError(httpCode: 502)
    /// HTTP code 503 - Service Unavailable
    public static let serviceUnavailable = RequestError(httpCode: 503)
    /// HTTP code 504 - Gateway Timeout
    public static let gatewayTimeout = RequestError(httpCode: 504)
    /// HTTP code 505 - HTTP Version Not Supported
    public static let httpVersionNotSupported = RequestError(httpCode: 505)
    /// HTTP code 506 - Variant Also Negotiates
    public static let variantAlsoNegotiates = RequestError(httpCode: 506)
    /// HTTP code 507 - Insufficient Storage
    public static let insufficientStorage = RequestError(httpCode: 507)
    /// HTTP code 508 - Loop Detected
    public static let loopDetected = RequestError(httpCode: 508)
    /// HTTP code 510 - Not Extended
    public static let notExtended = RequestError(httpCode: 510)
    /// HTTP code 511 - Network Authentication Required
    public static let networkAuthenticationRequired = RequestError(httpCode: 511)

    private static func reason(forHTTPCode code: Int) -> String {
        switch code {
            case 100: return "Continue"
            case 101: return "Switching Protocols"
            case 200: return "OK"
            case 201: return "Created"
            case 202: return "Accepted"
            case 203: return "Non-Authoritative Information"
            case 204: return "No Content"
            case 205: return "Reset Content"
            case 206: return "Partial Content"
            case 207: return "Multi-Status"
            case 208: return "Already Reported"
            case 226: return "IM Used"
            case 300: return "Multiple Choices"
            case 301: return "Moved Permanently"
            case 302: return "Found"
            case 303: return "See Other"
            case 304: return "Not Modified"
            case 305: return "Use Proxy"
            case 307: return "Temporary Redirect"
            case 308: return "Permanent Redirect"
            case 400: return "Bad Request"
            case 401: return "Unauthorized"
            case 402: return "Payment Required"
            case 403: return "Forbidden"
            case 404: return "Not Found"
            case 405: return "Method Not Allowed"
            case 406: return "Not Acceptable"
            case 407: return "Proxy Authentication Required"
            case 408: return "Request Timeout"
            case 409: return "Conflict"
            case 410: return "Gone"
            case 411: return "Length Required"
            case 412: return "Precondition Failed"
            case 413: return "Payload Too Large"
            case 414: return "URI Too Long"
            case 415: return "Unsupported Media Type"
            case 416: return "Range Not Satisfiable"
            case 417: return "Expectation Failed"
            case 421: return "Misdirected Request"
            case 422: return "Unprocessable Entity"
            case 423: return "Locked"
            case 424: return "Failed Dependency"
            case 426: return "Upgrade Required"
            case 428: return "Precondition Required"
            case 429: return "Too Many Requests"
            case 431: return "Request Header Fields Too Large"
            case 451: return "Unavailable For Legal Reasons"
            case 500: return "Internal Server Error"
            case 501: return "Not Implemented"
            case 502: return "Bad Gateway"
            case 503: return "Service Unavailable"
            case 504: return "Gateway Timeout"
            case 505: return "HTTP Version Not Supported"
            case 506: return "Variant Also Negotiates"
            case 507: return "Insufficient Storage"
            case 508: return "Loop Detected"
            case 510: return "Not Extended"
            case 511: return "Network Authentication Required"
            default: return "http_\(code)"
        }
    }
}

/**
 An object that conforms to QueryParams is identified as being decodable from URLEncoded data.
 This can be applied to a Codable route to define the names and types of the expected query parameters, and provide type-safe access to their values. The `QueryDecoder` is used to decode the URL encoded parameters into an instance of the conforming type.
 ### Usage Example: ###
 ```swift
 struct Query: QueryParams {
    let id: Int
 }
 router.get("/user") { (query: Query, respondWith: (User?, RequestError?) -> Void) in
     guard let user: User = userArray[query.id] else {
        return respondWith(nil, .notFound)
     }
     respondWith(user, nil)
 }
 ```
 ### Decoding Empty Values:
 When an HTML form is sent with an empty or unchecked field, the corresponding key/value pair is sent with an empty value (i.e. `&key1=&key2=`).
 The corresponding mapping to Swift types performed by `QueryDecoder` is as follows:
 - Any Optional type (including `String?`) defaults to `nil`
 - Non-optional `String` successfully decodes to `""`
 - Non-optional `Bool` decodes to `false`
 - All other non-optional types throw a decoding error
 */
public protocol QueryParams: Codable {

    /**
     The decoding strategy for Dates.
     The variable can be defined within your QueryParams object and tells the `QueryDecoder` how dates should be decoded.  The enum used for the DateDecodingStrategy is the same one found in the `JSONDecoder`.

     ### Usage Example: ###

     ```swift
     struct MyQuery: QueryParams {
        let date: Date
        static let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601
        static let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601
     }

     let queryParams = ["date": "2019-09-06T10:14:41+0000"]

     let query = try QueryDecoder(dictionary: queryParams).decode(MyQuery.self)
     ```
     */
    static var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { get }

    /**
     The encoding strategy for Dates.
     The variable would be defined within your QueryParams object and tells the `QueryEncoder` how dates should be encoded.  The enum used for the DateEncodingStrategy is the same one found in the `JSONEncoder`.

      ### Usage Example: ###

      ```swift
      struct MyQuery: QueryParams {
         let date: Date
         static let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601
         static let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601
      }

     let query = MyQuery(date: Date(timeIntervalSinceNow: 0))

     let myQueryDict: [String: String] = try QueryEncoder().encode(query)
     ```
      */
    static var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { get }
}

/// Defines default values for the `dateDecodingStrategy` and `dateEncodingStrategy`. The
/// default formatting for a `Date` in a `QueryParams` type is defined by `Coder.dateFormatter`,
/// which uses the "UTC" timezone and "yyyy-MM-dd'T'HH:mm:ssZ" date format.
extension QueryParams {

    /// Default value: `Coder.defaultDateFormatter`
    public static var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
        return .formatted(Coder.defaultDateFormatter)
    }

    /// Default value: `Coder.defaultDateFormatter`
    public static var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy {
        return .formatted(Coder.defaultDateFormatter)
    }

}

/**
 An error representing a failure to create an `Identifier`.

### Usage Example: ###

 An `QueryParamsError.invalidValue` may be thrown if the given type cannot be constructed from the given string.
 ````swift
 throw QueryParamsError.invalidValue
 ````
 */
public enum QueryParamsError: Error {
    /// Represents a failure to create a given filtering type from a given `String` representation.
    case invalidValue

}

/**
 An error representing a failure to create an `Identifier`.

### Usage Example: ###

 An `IdentifierError.invalidValue` may be thrown if the given string cannot be converted to an integer when using an `Identifier`.
 ````swift
 throw IdentifierError.invalidValue
 ````
 */
public enum IdentifierError: Error {
    /// Represents a failure to create an `Identifier` from a given `String` representation.
    case invalidValue
}

/**
 An identifier for an entity with a string representation.

### Usage Example: ###
 ````swift
 // Used in the Id field.
 public typealias IdentifierCodableClosure<Id: Identifier, I: Codable, O: Codable> = (Id, I, @escaping CodableResultClosure<O>) -> Void
 ````
 */
public protocol Identifier: Codable {
    /// Creates an identifier from a given string value.
    /// - Throws: An IdentifierError.invalidValue if the given string is not a valid representation.
    init(value: String) throws

    /// The string representation of the identifier.
    var value: String { get }
}

/**
 Extends `String` to comply to the `Identifier` protocol.

### Usage Example: ###
 ````swift
 // The Identifier used in the Id field could be a `String`.
 public typealias IdentifierCodableClosure<Id: Identifier, I: Codable, O: Codable> = (Id, I, @escaping CodableResultClosure<O>) -> Void
 ````
 */
extension String: Identifier {
    /// Creates a string identifier from a given string value.
    public init(value: String) {
        self.init(value)
    }

    /// The string representation of the identifier.
    public var value: String {
        return self
    }
}

/**
 Extends `Int` to comply to the `Identifier` protocol.

### Usage Example: ###
 ````swift
 // The Identifier used in the Id field could be an `Int`.
 public typealias IdentifierCodableClosure<Id: Identifier, I: Codable, O: Codable> = (Id, I, @escaping CodableResultClosure<O>) -> Void
 ````
 */
extension Int: Identifier {
    /// Creates an integer identifier from a given string representation.
    /// - Throws: An `IdentifierError.invalidValue` if the given string cannot be converted to an integer.
    public init(value: String) throws {
        if let id = Int(value) {
            self = id
        } else {
            throw IdentifierError.invalidValue
        }
    }

    /// The string representation of the identifier.
    public var value: String {
        return String(describing: self)
    }
}

/**
 Extends `Int8` to comply to the `Identifier` protocol.

### Usage Example: ###
 ````swift
 // The Identifier used in the Id field could be an `Int8`.
 public typealias IdentifierCodableClosure<Id: Identifier, I: Codable, O: Codable> = (Id, I, @escaping CodableResultClosure<O>) -> Void
 ````
 */
extension Int8: Identifier {
    /// Creates an integer identifier from a given string representation.
    /// - Throws: An `IdentifierError.invalidValue` if the given string cannot be converted to an integer.
    public init(value: String) throws {
        if let id = Int8(value) {
            self = id
        } else {
            throw IdentifierError.invalidValue
        }
    }

    /// The string representation of the identifier.
    public var value: String {
        return String(describing: self)
    }
}

/**
 Extends `Int16` to comply to the `Identifier` protocol.

### Usage Example: ###
 ````swift
 // The Identifier used in the Id field could be an `Int16`.
 public typealias IdentifierCodableClosure<Id: Identifier, I: Codable, O: Codable> = (Id, I, @escaping CodableResultClosure<O>) -> Void
 ````
 */
extension Int16: Identifier {
    /// Creates an integer identifier from a given string representation.
    /// - Throws: An `IdentifierError.invalidValue` if the given string cannot be converted to an integer.
    public init(value: String) throws {
        if let id = Int16(value) {
            self = id
        } else {
            throw IdentifierError.invalidValue
        }
    }

    /// The string representation of the identifier.
    public var value: String {
        return String(describing: self)
    }
}

/**
 Extends `Int32` to comply to the `Identifier` protocol.

### Usage Example: ###
 ````swift
 // The Identifier used in the Id field could be an `Int32`.
 public typealias IdentifierCodableClosure<Id: Identifier, I: Codable, O: Codable> = (Id, I, @escaping CodableResultClosure<O>) -> Void
 ````
 */
extension Int32: Identifier {
    /// Creates an integer identifier from a given string representation.
    /// - Throws: An `IdentifierError.invalidValue` if the given string cannot be converted to an integer.
    public init(value: String) throws {
        if let id = Int32(value) {
            self = id
        } else {
            throw IdentifierError.invalidValue
        }
    }

    /// The string representation of the identifier.
    public var value: String {
        return String(describing: self)
    }
}

/**
 Extends `Int64` to comply to the `Identifier` protocol.

### Usage Example: ###
 ````swift
 // The Identifier used in the Id field could be an `Int64`.
 public typealias IdentifierCodableClosure<Id: Identifier, I: Codable, O: Codable> = (Id, I, @escaping CodableResultClosure<O>) -> Void
 ````
 */
extension Int64: Identifier {
    /// Creates an integer identifier from a given string representation.
    /// - Throws: An `IdentifierError.invalidValue` if the given string cannot be converted to an integer.
    public init(value: String) throws {
        if let id = Int64(value) {
            self = id
        } else {
            throw IdentifierError.invalidValue
        }
    }

    /// The string representation of the identifier.
    public var value: String {
        return String(describing: self)
    }
}

/**
 Extends `UInt` to comply to the `Identifier` protocol.

### Usage Example: ###
 ````swift
 // The Identifier used in the Id field could be an `UInt`.
 public typealias IdentifierCodableClosure<Id: Identifier, I: Codable, O: Codable> = (Id, I, @escaping CodableResultClosure<O>) -> Void
 ````
 */
extension UInt: Identifier {
    /// Creates an unsigned integer identifier from a given string representation.
    /// - Throws: An `IdentifierError.invalidValue` if the given string cannot be converted to an unsigned integer.
    public init(value: String) throws {
        if let id = UInt(value) {
            self = id
        } else {
            throw IdentifierError.invalidValue
        }
    }

    /// The string representation of the identifier.
    public var value: String {
        return String(describing: self)
    }
}

/**
 Extends `UInt8` to comply to the `Identifier` protocol.

### Usage Example: ###
 ````swift
 // The Identifier used in the Id field could be an `UInt8`.
 public typealias IdentifierCodableClosure<Id: Identifier, I: Codable, O: Codable> = (Id, I, @escaping CodableResultClosure<O>) -> Void
 ````
 */
extension UInt8: Identifier {
    /// Creates an unsigned integer identifier from a given string representation.
    /// - Throws: An `IdentifierError.invalidValue` if the given string cannot be converted to an unsigned integer.
    public init(value: String) throws {
        if let id = UInt8(value) {
            self = id
        } else {
            throw IdentifierError.invalidValue
        }
    }

    /// The string representation of the identifier.
    public var value: String {
        return String(describing: self)
    }
}

/**
 Extends `UInt16` to comply to the `Identifier` protocol.

### Usage Example: ###
 ````swift
 // The Identifier used in the Id field could be an `UInt16`.
 public typealias IdentifierCodableClosure<Id: Identifier, I: Codable, O: Codable> = (Id, I, @escaping CodableResultClosure<O>) -> Void
 ````
 */
extension UInt16: Identifier {
    /// Creates an unsigned integer identifier from a given string representation.
    /// - Throws: An `IdentifierError.invalidValue` if the given string cannot be converted to an unsigned integer.
    public init(value: String) throws {
        if let id = UInt16(value) {
            self = id
        } else {
            throw IdentifierError.invalidValue
        }
    }

    /// The string representation of the identifier.
    public var value: String {
        return String(describing: self)
    }
}

/**
 Extends `UInt32` to comply to the `Identifier` protocol.

### Usage Example: ###
 ````swift
 // The Identifier used in the Id field could be an `UInt32`.
 public typealias IdentifierCodableClosure<Id: Identifier, I: Codable, O: Codable> = (Id, I, @escaping CodableResultClosure<O>) -> Void
 ````
 */
extension UInt32: Identifier {
    /// Creates an unsigned integer identifier from a given string representation.
    /// - Throws: An `IdentifierError.invalidValue` if the given string cannot be converted to an unsigned integer.
    public init(value: String) throws {
        if let id = UInt32(value) {
            self = id
        } else {
            throw IdentifierError.invalidValue
        }
    }

    /// The string representation of the identifier.
    public var value: String {
        return String(describing: self)
    }
}

/**
 Extends `UInt64` to comply to the `Identifier` protocol.

### Usage Example: ###
 ````swift
 // The Identifier used in the Id field could be an `UInt64`.
 public typealias IdentifierCodableClosure<Id: Identifier, I: Codable, O: Codable> = (Id, I, @escaping CodableResultClosure<O>) -> Void
 ````
 */
extension UInt64: Identifier {
    /// Creates an unsigned integer identifier from a given string representation.
    /// - Throws: An `IdentifierError.invalidValue` if the given string cannot be converted to an unsigned integer.
    public init(value: String) throws {
        if let id = UInt64(value) {
            self = id
        } else {
            throw IdentifierError.invalidValue
        }
    }

    /// The string representation of the identifier.
    public var value: String {
        return String(describing: self)
    }
}

extension Double: Identifier {
    /// Creates a double identifier from a given string representation.
    /// - Throws: An `IdentifierError.invalidValue` if the given string cannot be converted to a Double.
    public init(value: String) throws {
        if let id = Double(value) {
            self = id
        } else {
            throw IdentifierError.invalidValue
        }
    }

    /// The string representation of the identifier.
    public var value: String {
        return String(describing: self)
    }
}

extension Float: Identifier {
    /// Creates a float identifier from a given string representation.
    /// - Throws: An `IdentifierError.invalidValue` if the given string cannot be converted to a Float.
    public init(value: String) throws {
        if let id = Float(value) {
            self = id
        } else {
            throw IdentifierError.invalidValue
        }
    }

    /// The string representation of the identifier.
    public var value: String {
        return String(describing: self)
    }
}

extension Bool: Identifier {
    /// Creates a bool identifier from a given string representation.
    /// - Throws: An `IdentifierError.invalidValue` if the given string cannot be converted to a Bool.
    public init(value: String) throws {
        if let id = Bool(value) {
            self = id
        } else {
            throw IdentifierError.invalidValue
        }
    }

    /// The string representation of the identifier.
    public var value: String {
        return String(describing: self)
    }
}

extension UUID: Identifier {
    /// Creates a UUID identifier from a given string representation.
    /// - Throws: An `IdentifierError.invalidValue` if the given string cannot be converted to a UUID.
    public init(value: String) throws {
        if let id = UUID(uuidString: value) {
            self = id
        } else {
            throw IdentifierError.invalidValue
        }
    }

    /// The string representation of the identifier.
    public var value: String {
        return self.uuidString
    }
}

/**
  An enum containing the ordering information
  ### Usage Example: ###
  To order ascending by name, we would write:
  ```swift
  Order.asc("name")
  ```
*/

public enum Order: Codable {

  /// Represents an ascending order with an associated String value
  case asc(String)
  /// Represents a descending order with an associated String value
  case desc(String)

  // Coding Keys for encoding and decoding
  enum CodingKeys: CodingKey {
    case asc
    case desc
  }

  // Function to encode enum case
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .asc(let value):
      try container.encode(value, forKey: .asc)
    case .desc(let value):
      try container.encode(value, forKey: .desc)
    }
  }

  // Function to decode enum case
  public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      do {
          let ascValue =  try container.decode(String.self, forKey: .asc)
          self = .asc(ascValue)
      } catch {
          let descValue =  try container.decode(String.self, forKey: .desc)
          self = .desc(descValue)
      }
  }

  /// Description of the enum case
  public var description: String {
    switch self {
    case let .asc(value):
      return "asc(\(value))"
    case let .desc(value):
      return "desc(\(value))"
    }
  }

  /// Associated value of the enum case
  public var value: String {
    switch self {
    case let .asc(value):
      return value
    case let .desc(value):
      return value
    }
  }
}

/**
  A codable struct containing the ordering information
  ### Usage Example: ###
  To order ascending by name and descending by age, we would write:
  ```swift
     Ordering(by: .asc("name"), .desc("age"))
  ```
*/
public struct Ordering: Codable {
  /// Array of Orders
  var order: [Order]!

  /// Creates an Ordering instance from one or more Orders
  public init(by order: Order...) {
    self.order = order
  }

  /// Creates an Ordering instance from a given array of Orders.
  public init(by order: [Order]) {
    self.order = order
  }

  /// Creates an Ordering instance from a given string value.
  internal init(string value: String) throws {
    if !value.contains(",") {
      let extractedValue = try extractValue(value)
      if value.contains("asc") {
        self.order = [.asc(extractedValue)]
      } else if value.contains("desc") {
        self.order = [.desc(extractedValue)]
      } else {
        throw QueryParamsError.invalidValue
      }
    } else {
      self.order = try value.split(separator: ",").map { String($0) }.map {
        let extractedValue = try extractValue($0)
        if $0.contains("asc") {
          return .asc(extractedValue)
        } else if $0.contains("desc") {
          return .desc(extractedValue)
        } else {
          throw QueryParamsError.invalidValue
        }
      }
    }
  }

  // Function to extract the String value from the Order enum case
  private func extractValue(_ value: String) throws -> String {
#if swift(>=4.2)
    guard var startIndex = value.firstIndex(of: "("),
          let endIndex = value.firstIndex(of: ")") else {
      throw QueryParamsError.invalidValue
    }
#else
    guard var startIndex = value.index(of: "("),
          let endIndex = value.index(of: ")") else {
      throw QueryParamsError.invalidValue
    }
#endif

    startIndex = value.index(startIndex, offsetBy: 1)
    let extractedValue = value[startIndex..<endIndex]
    return String(extractedValue)
  }

  // The string representation of the Ordering instance
  internal func getStringValue() -> String {
    return self.order.map{ $0.description } .joined(separator: ",")
  }

  /// Returns an array of Orders
  public func getValues() -> [Order] {
    return self.order
  }
}


/**
  A codable struct containing the pagination information
  ### Usage Example: ###
  To get only the first 10 values, we would write:
  ```swift
  Pagination(size: 10)
  ```
  To get the 11th to 20th values, we would write:
  ```swift
  Pagination(start: 10, size: 10)
  ```
*/
public struct Pagination: Codable {
  private var start: Int
  private var size: Int

  /// Creates a Pagination instance from start and size Int values
  public init(start: Int  = 0, size: Int) {
    self.start = start
    self.size = size
  }

  internal init(string value: String) throws {
    let array = value.split(separator: ",")
    if array.count != 2 {
      throw QueryParamsError.invalidValue
    }
    self.start = try Int(value: String(array[0]))
    self.size = try Int(value: String(array[1]))
  }

  internal func getStringValue() -> String {
    return "\(start),\(size)"
  }

  /// Returns a tuple containing the start and size Int values
  public func getValues() -> (start: Int, size: Int) {
    return (start, size)
  }
}

/**
  An enum defining the available logical operators
  ### Usage Example: ###
  To use the OR Operator, we would write:
  ```swift
  Operator.or
  ```
*/
public enum Operator: String, Codable {
  /// OR Operator
  case or
  /// Equal Operator
  case equal
  /// LowerThan Operator
  case lowerThan
  /// LowerThanOrEqual Operator
  case lowerThanOrEqual
  /// GreaterThan Operator
  case greaterThan
  /// GreaterThanOrEqual Operator
  case greaterThanOrEqual
  /// ExclusiveRange Operator
  case exclusiveRange
  /// InclusiveRange Operator
  case inclusiveRange
}


/**
  An identifier for an operation object.
*/
public protocol Operation: Codable {
  /// Creates an Operation from a string value
  init(string: String) throws

  /// Returns the string representation of the parameters for an Operation to be used in the URL.
  ///
  /// ```swift
  ///  let range = InclusiveRange(start: 5, end: 10)
  /// ```
  /// would be represented as `"5,10"`, which in the URL would translate to: `?range=5,10`
  /// This URL format is not an API but an implementation detail that could change in the future.
  /// The URL doesn't encode the operator itself instead it is inferred at
  /// decoding time by the type information associated with that key.
  /// The type information used to decode this URL format is defined by
  /// the QueryParams structure associated with a route.
  /// The key name in the url maps to the field name in the QueryParams structure.
  func getStringValue() -> String

  /// Returns the Operator associated with the Operation.
  ///
  /// `InclusiveRange(start: 5, end: 10)` will have the operator `Operator.inclusiveRange`
  func getOperator() -> Operator
}


/**
  A codable struct enabling greater than filtering
  ### Usage Example: ###
  To filter with greaterThan on age which is an Integer, we would write:
  ```swift
  struct MyQuery: QueryParams {
    let age: GreaterThan<Int>
  }
  let query = MyQuery(age: GreaterThan(value: 8))
  ```
  In a URL it would translate to:
  ```
  ?age=8
  ```

  Note: The "age=8" format is not an API but an implementation detail that could change in the future.
*/
public struct GreaterThan<I: Identifier>: Operation {
  private var value: I
  private let `operator`: Operator = .greaterThan

  /// Creates a GreaterThan instance from a given Identifier value
  public init(value: I) {
    self.value = value
  }

  /// Creates a GreaterThan instance from a given String value
  public init(string value: String) throws {
    self.value = try I(value: value)
  }

  /// Returns the stored value
  public func getValue() -> I {
    return self.value
  }

  /// Returns the stored value as a String
  public func getStringValue() -> String {
    return self.value.value
  }

  /// Returns the Operator
  public func getOperator() -> Operator {
    return self.`operator`
  }
}

/**
  A codable struct enabling greater than or equal filtering
  ### Usage Example: ###
  To filter with greater than or equal on age which is an Integer, we would write:
  ```swift
  struct MyQuery: QueryParams {
    let age: GreaterThanOrEqual<Int>
  }
  let query = MyQuery(age: GreaterThanOrEqual>(value: 8))
  ```
  In a URL it would translate to:
  ```
  ?age=8
  ```

  Note: The "age=8" format is not an API but an implementation detail that could change in the future.
*/
public struct GreaterThanOrEqual<I: Identifier>: Operation {
  private var value: I
  private let `operator`: Operator = .greaterThanOrEqual

  /// Creates a GreaterThanOrEqual instance from a given Identifier value
  public init(value: I) {
    self.value = value
  }

  /// Creates a GreaterThanOrEqual instance from a given String value
  public init(string value: String) throws {
    self.value = try I(value: value)
  }

  /// Returns the stored value
  public func getValue() -> I {
    return self.value
  }

  /// Returns the stored value as a String
  public func getStringValue() -> String {
    return self.value.value
  }

  /// Returns the Operator
  public func getOperator() -> Operator {
    return self.`operator`
  }
}

/**
  A codable struct enabling lower than filtering
  ### Usage Example: ###
  To filter with lower than on age, we would write:
  ```swift
  struct MyQuery: QueryParams {
    let age: LowerThan<Int>
  }
  let query = MyQuery(age: LowerThan(value: 8))
  ```
  In a URL it would translate to:
  ```
  ?age=8
  ```

  Note: The "age=8" format is not an API but an implementation detail that could change in the future.
  ```
*/
public struct LowerThan<I: Identifier>: Operation {
  private var value: I
  private let `operator`: Operator = .lowerThan

  /// Creates a LowerThan instance from a given Identifier value
  public init(value: I) {
    self.value = value
  }

  /// Creates a LowerThan instance from a given String value
  public init(string value: String) throws {
    self.value = try I(value: value)
  }

  /// Returns the stored value
  public func getValue() -> I {
    return self.value
  }

  /// Returns the stored value as a String
  public func getStringValue() -> String {
    return String(describing: value)
  }

  /// Returns the Operator
  public func getOperator() -> Operator {
    return self.`operator`
  }
}

/**
  A codable struct enabling lower than or equal filtering
  ### Usage Example: ###
  To filter with lower than or equal on age, we would write:
  ```swift
  struct MyQuery: QueryParams {
    let age: LowerThanOrEqual<Int>
  }
  let query = MyQuery(age: LowerThanOrEqual(value: 8))
  ```
  In a URL it would translate to:
  ```
  ?age=8
  ```

  Note: The "age=8" format is not an API but an implementation detail that could change in the future.
*/
public struct LowerThanOrEqual<I: Identifier>: Operation {
  private var value: I
  private let `operator`: Operator = .lowerThanOrEqual

  /// Creates a LowerThan instance from a given Identifier value
  public init(value: I) {
    self.value = value
  }

  /// Creates a LowerThan instance from a given String value
  public init(string value: String) throws {
    self.value = try I(value: value)
  }

  /// Returns the stored value
  public func getValue() -> I {
    return self.value
  }

  /// Returns the stored value as a String
  public func getStringValue() -> String {
    return String(describing: value)
  }

  /// Returns the Operator
  public func getOperator() -> Operator {
    return self.`operator`
  }
}

/**
  A codable struct enabling to filter with an inclusive range
  ### Usage Example: ###
  To filter on age using an inclusive range, we would write:
  ```swift
  struct MyQuery: QueryParams {
    let age: InclusiveRange<Int>
  }
  let query = MyQuery(age: InclusiveRange(start: 8, end: 14))
  ```
  In a URL it would translate to:
  ```
  ?age=8,14
  ```

  Note: The "age=8,14" format is not an API but an implementation detail that could change in the future.
*/
public struct InclusiveRange<I: Identifier>: Operation {
  private var start: I
  private var end: I
  private let `operator`: Operator = .inclusiveRange

  /// Creates a InclusiveRange instance from given start and end values
  public init(start: I, end: I) {
    self.start = start
    self.end = end
  }

  /// Creates a InclusiveRange instance from a given String value
  public init(string value: String) throws {
    let array = value.split(separator: ",")
    if array.count != 2 {
      throw QueryParamsError.invalidValue
    }
    self.start = try I(value: String(array[0]))
    self.end = try I(value: String(array[1]))
  }

  /// Returns the stored values as a tuple
  public func getValue() -> (start: I, end: I) {
    return (start: self.start, end: self.end)
  }

  /// Returns the stored value as a String
  public func getStringValue() -> String {
    return "\(start),\(end)"
  }

  /// Returns the Operator
  public func getOperator() -> Operator {
    return self.`operator`
  }
}

/**
  A codable struct enabling to filter with an exlusive range
  ### Usage Example: ###
  To filter on age using an exclusive range, we would write:
  ```swift
  struct MyQuery: QueryParams {
    let age: ExclusiveRange<Int>
  }
  let query = MyQuery(age: ExclusiveRange(start: 8, end: 14))
  ```
  In a URL it would translate to:
  ```
  ?age=8,14
  ```

  Note: The "age=8,14" format is not an API but an implementation detail that could change in the future.
*/
public struct ExclusiveRange<I: Identifier>: Operation {
  private var start: I
  private var end: I
  private let `operator`: Operator = .exclusiveRange

  /// Creates a ExclusiveRange instance from given start and end values
  public init(start: I, end: I) {
    self.start = start
    self.end = end
  }

  /// Creates a ExclusiveRange instance from a given String value
  public init(string value: String) throws {
    let array = value.split(separator: ",")
    if array.count != 2 {
      throw QueryParamsError.invalidValue
    }
    self.start = try I(value: String(array[0]))
    self.end = try I(value: String(array[1]))
  }

  /// Returns the stored values as a tuple
  public func getValue() -> (start: I, end: I) {
    return (start: self.start, end: self.end)
  }

  /// Returns the stored value as a String
  public func getStringValue() -> String {
    return "\(start),\(end)"
  }

  /// Returns the Operator
  public func getOperator() -> Operator {
    return self.`operator`
  }
}

//public protocol Persistable: Codable {
//    // Related types
//    associatedtype Id: Identifier
//
//    // Create
//    static func create(model: Self, respondWith: @escaping (Self?, RequestError?) -> Void)
//    // Read
//    static func read(id: Id, respondWith: @escaping (Self?, RequestError?) -> Void)
//    // Read all
//    static func read(respondWith: @escaping ([Self]?, RequestError?) -> Void)
//    // Update
//    static func update(id: Id, model: Self, respondWith: @escaping (Self?, RequestError?) -> Void)
//    // How about returning Identifer instances for the delete operations?
//    // Delete
//    static func delete(id: Id, respondWith: @escaping (RequestError?) -> Void)
//    // Delete all
//    static func delete(respondWith: @escaping (RequestError?) -> Void)
//}
//
//// Provides utility methods for getting the type  and routes for the class
//// conforming to Persistable
//public extension Persistable {
//    // Set up name space based on name of model (e.g. User -> user(s))
//    static var type: String {
//        let kind = String(describing: Swift.type(of: self))
//        return String(kind.characters.dropLast(5))
//    }
//    static var typeLowerCased: String { return "\(type.lowercased())" }
//    static var route: String { return "/\(typeLowerCased)s" }
//}
