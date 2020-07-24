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

/**
 Class defining shared resources for the [QueryDecoder](https://github.com/IBM-Swift/KituraContracts/blob/master/Sources/KituraContracts/CodableQuery/QueryDecoder.swift) and [QueryEncoder](https://github.com/IBM-Swift/KituraContracts/blob/master/Sources/KituraContracts/CodableQuery/QueryEncoder.swift).
 
 ### Usage Example: ###
 ````swift
 let date = Coder.defaultDateFormatter.date(from: "2017-10-31T16:15:56+0000")!
 ````
 */
public class Coder {

    @available(*, deprecated, message: "Use Coder.defaultDateFormatter instead")
    public let dateFormatter: DateFormatter = Coder.defaultDateFormatter

    /**
     The default [DateFormatter](https://developer.apple.com/documentation/foundation/dateformatter) used for encoding and decoding query parameters. It uses the "UTC" timezone and "yyyy-MM-dd'T'HH:mm:ssZ" date format.

     ### Usage Example: ###
     ````swift
     let date = Coder.defaultDateFormatter.date(from: "2017-10-31T16:15:56+0000")
     ````
     */
    public static let defaultDateFormatter: DateFormatter = {
        let value = DateFormatter()
        value.timeZone = TimeZone(identifier: "UTC")
        value.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return value
    }()

    /**
    Initializes a `Coder` instance with a `DateFormatter`
    using the "UTC" timezone and "yyyy-MM-dd'T'HH:mm:ssZ" date format.
     */
    public init() {}

    /**
     Helper method to extract the field name from a `CodingKey` array.
     
     ### Usage Example: ###
     ````swift
     let fieldName = Coder.getFieldName(from: codingPath)
     ````
     */
    public static func getFieldName(from codingPath: [CodingKey]) -> String {
        #if swift(>=4.1)
            return codingPath.compactMap({$0.stringValue}).joined(separator: ".")
        #else
            return codingPath.flatMap({$0.stringValue}).joined(separator: ".")
        #endif
    }
}
