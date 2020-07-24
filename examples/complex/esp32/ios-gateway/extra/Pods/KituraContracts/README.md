<p align="center">
<a href="https://www.kitura.io/">
<img src="https://raw.githubusercontent.com/IBM-Swift/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
</a>
</p>


<p align="center">
<a href="https://ibm-swift.github.io/KituraContracts/index.html">
<img src="https://img.shields.io/badge/apidoc-KituraContracts-1FBCE4.svg?style=flat" alt="APIDoc">
</a>
<a href="https://travis-ci.org/IBM-Swift/KituraContracts">
<img src="https://travis-ci.org/IBM-Swift/KituraContracts.svg?branch=master" alt="Build Status - Master">
</a>
<img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
<img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
<a href="http://swift-at-ibm-slack.mybluemix.net/">
<img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg" alt="Slack Status">
</a>
</p>

# KituraContracts

## Summary

KituraContracts is a library containing type definitions shared by client (e.g. [KituraKit](https://ibm-swift.github.io/KituraKit/)) and server (e.g. [Kitura](https://ibm-swift.github.io/Kitura)) code. These shared type definitions include [Codable Closure Aliases](https://ibm-swift.github.io/KituraContracts/Typealiases.html), [RequestError](https://ibm-swift.github.io/KituraContracts/Structs/RequestError.html), [QueryEncoder](https://ibm-swift.github.io/KituraContracts/Classes/QueryEncoder.html), [QueryDecoder](https://ibm-swift.github.io/KituraContracts/Classes/QueryDecoder.html), [Coder](https://ibm-swift.github.io/KituraContracts/Classes/Coder.html), [Identifier Protocol](https://ibm-swift.github.io/KituraContracts/Protocols/Identifier.html#/s:15KituraContracts10IdentifierP5valueSSv) and [Extensions](https://ibm-swift.github.io/KituraContracts/Extensions.html#/s:SS) to String and Int, which add conformity to the Identifier protocol.

## Usage

KituraContracts represents the types and protocols that are common to both the [Kitura](https://github.com/IBM-Swift/Kitura) server and [KituraKit](https://github.com/IBM-Swift/KituraKit) client side library. If you are using Kitura or KituraKit, your project does not need to depend on KituraContracts explicitly.

#### Add dependencies

Add the `KituraContracts` package to the dependencies within your application’s `Package.swift` file. Substitute `"x.x.x"` with the latest `KituraContracts` [release](https://github.com/IBM-Swift/KituraContracts/releases).

```swift
.package(url: "https://github.com/IBM-Swift/KituraContracts.git", from: "x.x.x")
```

Add `KituraContracts` to your target's dependencies:

```swift
.target(name: "example", dependencies: ["KituraContracts"]),
```

#### Import package

```swift
import KituraContracts
```

## Example

This example, shows how to use a shared type definition for `RequestError` within a router POST method on `users`. If no errors occurred and you have a `User` you can respond with the user and pass nil as the `RequestError?` value. If there has been an error you can respond with an appropriate error and pass nil for the `User?`.

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

## Swift version

The 1.x.x releases were tested on macOS and Linux using the Swift 4.1 binaries. Please note that this is the default version of Swift that is included in [Xcode 9.3](https://developer.apple.com/xcode/).

## API Documentation
For more information visit our [API reference](https://ibm-swift.github.io/KituraContracts/index.html).

## Community

We love to talk server-side Swift and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License

This library is licensed under Apache 2.0. Full license text is available in [LICENSE](https://github.com/IBM-Swift/KituraContracts/blob/master/LICENSE).
