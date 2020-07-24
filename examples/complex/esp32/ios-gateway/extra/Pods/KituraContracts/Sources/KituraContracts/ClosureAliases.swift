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

// MARK: Codable Type Aliases

/**
The `ResultClosure` is used by other `Codable` aliases when responding with only a `RequestError` is needed.
 
The following two typealiases make use of `ResultClosure`:
 ````swift
 public typealias NonCodableClosure = (@escaping ResultClosure) -> Void
 
 public typealias IdentifierNonCodableClosure<Id: Identifier> = (Id, @escaping ResultClosure) -> Void
 ````
 */
public typealias ResultClosure = (RequestError?) -> Void

/**
The `CodableResultClosure` is used by other `Codable` aliases when responding with an object which conforms to `Codable`, or a `RequestError` is needed.
 
The following two typealiases make use of `CodableResultClosure`:
 ````swift
 public typealias IdentifierCodableClosure<Id: Identifier, I: Codable, O: Codable> = (Id, I, @escaping CodableResultClosure<O>) -> Void
 
 public typealias CodableClosure<I: Codable, O: Codable> = (I, @escaping CodableResultClosure<O>) -> Void
 ````
 */
public typealias CodableResultClosure<O: Codable> = (O?, RequestError?) -> Void

/**
The `CodableArrayResultClosure` is used by other `Codable` aliases when responding with an array of objects which conform to `Codable`, or a `RequestError` is needed.
 
 The following typealias makes use of `CodableArrayResultClosure`:
 ````swift
 public typealias CodableArrayClosure<O: Codable> = (@escaping CodableArrayResultClosure<O>) -> Void
 ````
 */
public typealias CodableArrayResultClosure<O: Codable> = ([O]?, RequestError?) -> Void

/**
The `IdentifierCodableArrayResultClosure` is used by other `Codable` aliases when responding with an array of tuples containing an identifier and a `Codable` object, or a `RequestError`.
 
 The following typealias makes use of `IdentifierCodableArrayResultClosure`:
 ````swift
 public typealias CodableIdentifierClosure<I: Codable, Id: Identifier, O: Codable> = (I, @escaping IdentifierCodableResultClosure<[Id, O]?>) -> Void
 ````
*/
public typealias IdentifierCodableArrayResultClosure<Id: Identifier, O: Codable> = ([(Id, O)]?, RequestError?) -> Void

/**
This is used to perform a series of actions which use an object conforming to `Identifier` and an object conforming to `Codable`. After which you want to respond with an object which conforms to `Codable`, which is of the same type as the object passed as a parameter, or respond with an `Identifier` or `RequestError`.
 
 The following typealias makes use of `IdentifierCodableResultClosure`:
 ````swift
 public typealias CodableIdentifierClosure<I: Codable, Id: Identifier, O: Codable> = (I, @escaping IdentifierCodableResultClosure<Id, O>) -> Void
 ````
 */
public typealias IdentifierCodableResultClosure<Id: Identifier, O: Codable> = (Id?, O?, RequestError?) -> Void

/**
The `IdentifierCodableClosure` is used to perform a series of actions utilising an object conforming to `Identifier` and an object conforming to 'Codable', then respond with an object which conforms to `Codable`, which is of the same type as the object passed as a parameter, or responding with a `RequestError` in the form of a `CodableResultClosure`.
 
By default `Int` has conformity to `Identifier`. In this example, if there has been an error you can use the `respondWith` call to respond with an appropriate error, passing nil for the `User?`. If no errors occurred and you have a `User`, you can just respond with the user, passing nil as the `RequestError?` value.
### Usage Example: ###
````swift
public struct User: Codable {
  ...
}

var userStore: [Int, User] = [...]

router.put("/users") { (id: Int, user: User, respondWith: (User?, RequestError?) -> Void) in
  guard let oldUser = self.userStore[id] else {
      respondWith(nil, .notFound)
      return
  }

  ...
 
  respondWith(user, nil)
}
````
*/
public typealias IdentifierCodableClosure<Id: Identifier, I: Codable, O: Codable> = (Id, I, @escaping CodableResultClosure<O>) -> Void

/**
The `CodableClosure` is used to perform a series of actions utilising an object conforming to `Identifier`, then respond with an object which conforms to `Codable`, which is of the same type as the object passed as a parameter, or responding with a `RequestError` in the form of a `CodableResultClosure`.

If no errors occurred and you have a `User`, you can just respond with the user by passing nil as the `RequestError?` value. In this example, if there has been an error you can use the `respondWith` call to respond with an appropriate error and passing nil for the `User?`.
### Usage Example: ###
````swift
public struct User: Codable {
  ...
}

router.post("/users") { (user: User, respondWith: (User?, RequestError?) -> Void) in
  if databaseConnectionIsOk {
      ...
      respondWith(user, nil)
  } else {
      ...
      respondWith(nil, .internalServerError)
  }
}
````
*/
public typealias CodableClosure<I: Codable, O: Codable> = (I, @escaping CodableResultClosure<O>) -> Void

/**
The `CodableIdentifierClosure` is used to perform a series of actions utilising an object conforming to `Identifier`, then respond with an object which conforms to `Codable`, and/or an object conforming to `Identifier` or responding with a `RequestError` in the form of a `IdentifierCodableResultClosure`.

 If no errors occurred and you have a `User` and the corresponding identifier, you can just respond with the identifier and user, and pass nil as the `RequestError?` value. In this example, if there has been an error you can use the `respondWith` call to respond with an appropriate error and passing nil for `Int?` and nil for `User?`.
### Usage Example: ###
````swift
public struct User: Codable {
  ...
}

router.post("/users") { (user: User, respondWith: (Int?, User?, RequestError?) -> Void) in
  if databaseConnectionIsOk {
      ...
      respondWith(id, user, nil)
  } else {
      ...
      respondWith(nil, nil, .internalServerError)
  }
}
````
*/
public typealias CodableIdentifierClosure<I: Codable, Id: Identifier, O: Codable> = (I, @escaping IdentifierCodableResultClosure<Id, O>) -> Void

/**
The `NonCodableClosure` is used to perform a series of actions then respond with a `RequestError` in the form of a `ResultClosure`.

If no errors occurred you can just pass nil as the `RequestError?` value. In this example, if there has been an error you can use the `respondWith` call to respond with an appropriate error.
### Usage Example: ###
````swift
router.delete("/users") { (respondWith: (RequestError?) -> Void) in
    if databaseConnectionIsOk {
      ...
      respondWith(nil)
    } else {
      respondWith(.internalServerError)
      ...
    }
}
````
*/
public typealias NonCodableClosure = (@escaping ResultClosure) -> Void

/**
The `IdentifierNonCodableClosure` is used to perform a series of actions utilising an object which conforms to `Identifier`, then respond with a `RequestError` in the form of a `ResultClosure`.

If no errors occurred you can just pass nil as the `RequestError?` value. In this example, if there has been an error you can use the `respondWith` call to respond with an appropriate error.
### Usage Example: ###
````swift
router.delete("/users") { (id: Int, respondWith: (RequestError?) -> Void) in
  if databaseConnectionIsOk {
      ...
      respondWith(nil)
  } else {
      ...
      respondWith(.internalServerError)
  }
}
````
*/
public typealias IdentifierNonCodableClosure<Id: Identifier> = (Id, @escaping ResultClosure) -> Void

/**
The `CodableArrayClosure` is used to perform a series of actions then respond with an array of objects conforming to `Codable` or a `RequestError` in the form of a `CodableArrayResultClosure`.

If no errors occurred and you have an array of `Users` you can just respond with the users by passing nil as the `RequestError?` value. In this example, if there has been an error you can use the `respondWith` call to respond with an appropriate error and passing nil for the `[User]?`.
### Usage Example: ###
````swift
router.get("/users") { (respondWith: ([User]?, RequestError?) -> Void) in
  if databaseConnectionIsOk {
      ...
      respondWith(users, nil)
  } else {
      ...
      respondWith(nil, .internalServerError)
  }
}
````
*/
public typealias CodableArrayClosure<O: Codable> = (@escaping CodableArrayResultClosure<O>) -> Void

/**
 The `IdentifierCodableArrayClosure` is used to perform a series of actions then respond with an array of tuples containing an identifier and a Codable object, or a `RequestError`, in the form of a `IdentifierCodableArrayResultClosure`.
 
 If no errors occurred and you have an array of `Users` you can just respond with the users by passing nil as the `RequestError?` value. In this example, if there has been an error you can use the `respondWith` call to respond with an appropriate error and passing nil for the `[User]?`.
 ### Usage Example: ###
 ````swift
 router.get("/users") { (respondWith: ([(Int, User)]?, RequestError?) -> Void) in
    if databaseConnectionIsOk {
        ...
        respondWith([(Int, User)], nil)
    } else {
        ...
        respondWith(nil, .internalServerError)
    }
 }
 ````
 */
public typealias IdentifierCodableArrayClosure<Id: Identifier, O: Codable> = (@escaping IdentifierCodableArrayResultClosure<Id, O>) -> Void

/**
The `SimpleCodableClosure` is used to perform a series of actions, then respond with an object conforming to `Codable` or a `RequestError` in the form of a `CodableResultClosure`.

### Usage Example: ###
````swift
public struct Status: Codable {
  ...
}

router.get("/status") { (respondWith: (Status?, RequestError?) -> Void) in
  ...
  respondWith(status, nil)
}
````
*/
public typealias SimpleCodableClosure<O: Codable> = (@escaping CodableResultClosure<O>) -> Void

/**
The `IdentifierSimpleCodableClosure` is used to perform a series of actions utilising an object which conforms to `Identifier`, then respond with an object conforming to `Codable` or a `RequestError` in the form of a `CodableResultClosure`.
 
If there has been an error you can use the `respondWith` call to respond with an appropriate error and passing nil for the `User?`. In this example, if no errors occurred and you have a `User` you can just respond with the user by passing nil as the `RequestError?` value.
### Usage Example: ###
````swift
public struct User: Codable {
  ...
}

var userStore: [Int, User] = (...)

router.get("/users") { (id: Int, respondWith: (User?, RequestError?) -> Void) in
  guard let user = self.userStore[id] else {
      respondWith(nil, .notFound)
      return
  }
  ...
  respondWith(user, nil)
}
````
*/
public typealias IdentifierSimpleCodableClosure<Id: Identifier, O: Codable> = (Id, @escaping CodableResultClosure<O>) -> Void
