<p align="center">
    <a href="http://kitura.io/">
        <img src="https://raw.githubusercontent.com/IBM-Swift/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>


<p align="center">
    <a href="https://ibm-swift.github.io/LoggerAPI/index.html">
    <img src="https://img.shields.io/badge/apidoc-LoggerAPI-1FBCE4.svg?style=flat" alt="APIDoc">
    </a>
    <a href="https://travis-ci.org/IBM-Swift/LoggerAPI">
    <img src="https://travis-ci.org/IBM-Swift/LoggerAPI.svg?branch=master" alt="Build Status - Master">
    </a>
    <img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
    <img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
    <img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
    <a href="http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg" alt="Slack Status">
    </a>
</p>

# LoggerAPI

A logger protocol that provides a common logging interface for different kinds of loggers. In addition, a class with a set of static functions for logging within your code is provided.

[Kitura](https://github.com/IBM-Swift/Kitura) uses this API throughout its implementation when logging.

## Usage

#### Add dependencies

Add the `LoggerAPI` package to the dependencies within your application’s `Package.swift` file. Substitute `"x.x.x"` with the latest `LoggerAPI` [release](https://github.com/IBM-Swift/LoggerAPI/releases):

```swift
.package(url: "https://github.com/IBM-Swift/LoggerAPI.git", from: "x.x.x")
```
Add `LoggerAPI` to your target's dependencies:
```swift
.target(name: "example", dependencies: ["LoggerAPI"]),
```

#### Import package

```swift
import LoggerAPI
````

#### Log messages

Add log messages to your application:
```swift
Log.warning("This is a warning.")
Log.error("This is an error.")
```

#### Define a logger

You need to define a `logger` in order to output these messages:
```swift
Log.logger = ...
```
You can write your own logger implementation. In the case of Kitura, it defines
`HeliumLogger` as the logger used by `LoggerAPI`. You can find out more about HeliumLogger [here](https://github.com/IBM-Swift/HeliumLogger/blob/master/README.md).

## API documentation

For more information visit our [API reference](http://ibm-swift.github.io/LoggerAPI/).

## Community

We love to talk server-side Swift, and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License

This library is licensed under Apache 2.0. Full license text is available in [LICENSE](https://github.com/IBM-Swift/LoggerAPI/blob/master/LICENSE.txt).
