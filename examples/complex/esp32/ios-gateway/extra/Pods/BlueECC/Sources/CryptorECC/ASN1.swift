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

// Private and public keys are stores in ASN1 format.
// The following code is used to parse the data and retrieve the required elements.  
struct ASN1 {

    indirect enum ASN1Element {
        case seq(elements: [ASN1Element])
        case integer(int: Int)
        case bytes(data: Data)
        case constructed(tag: Int, elem: ASN1Element)
        case unknown
    }

    static func toASN1Element(data: Data) -> (ASN1Element, Int) {
        guard data.count >= 2 else {
            // format error
            return (.unknown, data.count)
        }

        switch data[0] {
        case 0x30: // sequence
            let (length, lengthOfLength) = readLength(data: data.advanced(by: 1))
            var result: [ASN1Element] = []
            var subdata = data.advanced(by: 1 + lengthOfLength)
            var alreadyRead = 0

            while alreadyRead < length {
                let (e, l) = toASN1Element(data: subdata)
                result.append(e)
                subdata = subdata.count > l ? subdata.advanced(by: l) : Data()
                alreadyRead += l
            }
            return (.seq(elements: result), 1 + lengthOfLength + length)

        case 0x02: // integer
            let (length, lengthOfLength) = readLength(data: data.advanced(by: 1))
            if length < 8 {
                var result: Int = 0
                let subdata = data.advanced(by: 1 + lengthOfLength)
                // ignore negative case
                for i in 0..<length {
                    result = 256 * result + Int(subdata[i])
                }
                return (.integer(int: result), 1 + lengthOfLength + length)
            }
            // number is too large to fit in Int; return the bytes
            return (.bytes(data: data.subdata(in: (1 + lengthOfLength) ..< (1 + lengthOfLength + length))), 1 + lengthOfLength + length)


        case let s where (s & 0xe0) == 0xa0: // constructed
            let tag = Int(s & 0x1f)
            let (length, lengthOfLength) = readLength(data: data.advanced(by: 1))
            let subdata = data.advanced(by: 1 + lengthOfLength)
            let (e, _) = toASN1Element(data: subdata)
            return (.constructed(tag: tag, elem: e), 1 + lengthOfLength + length)

        default: // octet string
            let (length, lengthOfLength) = readLength(data: data.advanced(by: 1))
            return (.bytes(data: data.subdata(in: (1 + lengthOfLength) ..< (1 + lengthOfLength + length))), 1 + lengthOfLength + length)
        }
    }

    static private func readLength(data: Data) -> (Int, Int) {
        if data[0] & 0x80 == 0x00 { // short form
            return (Int(data[0]), 1)
        } else {
            let lenghOfLength = Int(data[0] & 0x7F)
            var result: Int = 0
            for i in 1..<(1 + lenghOfLength) {
                result = 256 * result + Int(data[i])
            }
            return (result, 1 + lenghOfLength)
        }
    }
}
