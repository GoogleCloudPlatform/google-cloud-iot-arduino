/**
 * Copyright IBM Corporation 2016 - 2019
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

import Logging
import Foundation

/// Implement the `CustomStringConvertible` protocol for the `LoggerMessageType` enum
extension LoggerMessageType: CustomStringConvertible {
    /// Convert a `LoggerMessageType` into a printable format.
    public var description: String {
        switch self {
        case .entry:
            return "ENTRY"
        case .exit:
            return "EXIT"
        case .debug:
            return "DEBUG"
        case .verbose:
            return "VERBOSE"
        case .info:
            return "INFO"
        case .warning:
            return "WARNING"
        case .error:
            return "ERROR"
        }
    }
}

/// A logger protocol implemented by Logger implementations. This API is used by Kitura
/// throughout its implementation when logging.
public protocol Logger {

    /// Output a logged message.
    ///
    /// - Parameter type: The type of the message (`LoggerMessageType`) being logged.
    /// - Parameter msg: The message to be logged.
    /// - Parameter functionName: The name of the function invoking the logger API.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API.
    /// - Parameter fileName: The file containing the source code of the function invoking the
    ///                      logger API.
    func log(_ type: LoggerMessageType, msg: String,
        functionName: String, lineNum: Int, fileName: String)
    
    /// Indicates if a message with a specified type (`LoggerMessageType`) will be in the logger
    /// output (i.e. will not be filtered out).
    ///
    /// - Parameter type: The type of message (`LoggerMessageType`).
    ///
    /// - Returns: A Boolean indicating whether a message of the specified type
    ///           (`LoggerMessageType`) will be in the logger output.
    func isLogging(_ level: LoggerMessageType) -> Bool

}

extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return try body()
    }
}

/// A class of static members used by anyone who wants to log messages.
public class Log {

    private static var _logger: Logger?
    private static var _loggerLock: NSLock = NSLock()

    /// An instance of the logger. It should usually be the one and only reference
    /// of the `Logger` protocol implementation in the system.
    /// This can be used in addition to `swiftLogger`, in which case log messages
    /// will be sent to both loggers.
    public static var logger: Logger? {
        get {
            return self._loggerLock.withLock { self._logger }
        }
        set {
            self._loggerLock.withLock { self._logger = newValue }
        }
    }

    private static var _swiftLogger: Logging.Logger?
    private static var _swiftLoggerLock: NSLock = NSLock()

    /// An instance of a swift-log Logger. If set, LoggerAPI will direct log messages
    /// to swift-log. This can be used in addition to `logger`, in which case log
    /// messages will be sent to both loggers.
    public static var swiftLogger: Logging.Logger? {
        get {
            return self._swiftLoggerLock.withLock { self._swiftLogger }
        }
        set {
            self._swiftLoggerLock.withLock { self._swiftLogger = newValue }
        }
    }

    /// Log a message for use when in verbose logging mode.
    ///
    /// - Parameter msg: The message to be logged.
    /// - Parameter functionName: The name of the function invoking the logger API.
    ///                          Defaults to the name of the function invoking
    ///                          this function.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API. Defaults to the line of the
    ///                     function invoking this function.
    /// - Parameter fileName: The file containing the source code of the function invoking the
    ///                      logger API. Defaults to the name of the file containing the function
    ///                      which invokes this function.
    public static func verbose(_ msg: @autoclosure () -> String, functionName: String = #function,
        lineNum: Int = #line, fileName: String = #file ) {
            if let logger = logger, logger.isLogging(.verbose) {
                logger.log( .verbose, msg: msg(),
                    functionName: functionName, lineNum: lineNum, fileName: fileName)
            }
            swiftLogger?.info("\(msg())")
    }

    /// Log an informational message.
    ///
    /// - Parameter msg: The message to be logged.
    /// - Parameter functionName: The name of the function invoking the logger API.
    ///                          Defaults to the name of the function invoking
    ///                          this function.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API. Defaults to the line of the
    ///                     function invoking this function.
    /// - Parameter fileName: The file containing the source code of the function invoking the
    ///                      logger API. Defaults to the name of the file containing the function
    ///                      which invokes this function.
    public class func info(_ msg: @autoclosure () -> String, functionName: String = #function,
        lineNum: Int = #line, fileName: String = #file) {
            if let logger = logger, logger.isLogging(.info) {
                logger.log( .info, msg: msg(),
                    functionName: functionName, lineNum: lineNum, fileName: fileName)
            }
            swiftLogger?.notice("\(msg())")
    }

    /// Log a warning message.
    ///
    /// - Parameter msg: The message to be logged.
    /// - Parameter functionName: The name of the function invoking the logger API.
    ///                          Defaults to the name of the function invoking
    ///                          this function.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API. Defaults to the line of the
    ///                     function invoking this function.
    /// - Parameter fileName: The file containing the source code of the function invoking the
    ///                      logger API. Defaults to the name of the file containing the function
    ///                      which invokes this function.
    public class func warning(_ msg: @autoclosure () -> String, functionName: String = #function,
        lineNum: Int = #line, fileName: String = #file) {
            if let logger = logger, logger.isLogging(.warning) {
                logger.log( .warning, msg: msg(),
                            functionName: functionName, lineNum: lineNum, fileName: fileName)
            }
            swiftLogger?.warning("\(msg())")
    }

    /// Log an error message.
    ///
    /// - Parameter msg: The message to be logged.
    /// - Parameter functionName: The name of the function invoking the logger API.
    ///                          Defaults to the name of the function invoking
    ///                          this function.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API. Defaults to the line of the
    ///                     function invoking this function.
    /// - Parameter fileName: The file containing the source code of the function invoking the
    ///                      logger API. Defaults to the name of the file containing the function
    ///                      which invokes this function.
    public class func error(_ msg: @autoclosure () -> String, functionName: String = #function,
        lineNum: Int = #line, fileName: String = #file) {
            if let logger = logger, logger.isLogging(.error) {
                logger.log( .error, msg: msg(),
                            functionName: functionName, lineNum: lineNum, fileName: fileName)
            }
            swiftLogger?.error("\(msg())")
    }

    /// Log a debugging message.
    ///
    /// - Parameter msg: The message to be logged.
    /// - Parameter functionName: The name of the function invoking the logger API.
    ///                          Defaults to the name of the function invoking
    ///                          this function.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API. Defaults to the line of the
    ///                     function invoking this function.
    /// - Parameter fileName: The file containing the source code of the function invoking the
    ///                      logger API. Defaults to the name of the file containing the function
    ///                      which invokes this function.
    public class func debug(_ msg: @autoclosure () -> String, functionName: String = #function,
        lineNum: Int = #line, fileName: String = #file) {
            if let logger = logger, logger.isLogging(.debug) {
                logger.log( .debug, msg: msg(),
                            functionName: functionName, lineNum: lineNum, fileName: fileName)
            }
            swiftLogger?.debug("\(msg())")
    }
    
    /// Log a message when entering a function.
    ///
    /// - Parameter msg: The message to be logged.
    /// - Parameter functionName: The name of the function invoking the logger API.
    ///                          Defaults to the name of the function invoking
    ///                          this function.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API. Defaults to the line of the
    ///                     function invoking this function.
    /// - Parameter fileName: The file containing the source code of the function invoking the
    ///                      logger API. Defaults to the name of the file containing the function
    ///                      which invokes this function.
    public class func entry(_ msg: @autoclosure () -> String, functionName: String = #function,
        lineNum: Int = #line, fileName: String = #file) {
            if let logger = logger, logger.isLogging(.entry) {
                logger.log(.entry, msg: msg(),
                           functionName: functionName, lineNum: lineNum, fileName: fileName)
            }
            swiftLogger?.trace("\(msg())")
    }
    
    /// Log a message when exiting a function.
    ///
    /// - Parameter msg: The message to be logged.
    /// - Parameter functionName: The name of the function invoking the logger API.
    ///                          Defaults to the name of the function invoking
    ///                          this function.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API. Defaults to the line of the
    ///                     function invoking this function.
    /// - Parameter fileName: The file containing the source code of the function invoking the
    ///                      logger API. Defaults to the name of the file containing the function
    ///                      which invokes this function.
    public class func exit(_ msg: @autoclosure () -> String, functionName: String = #function,
        lineNum: Int = #line, fileName: String = #file) {
            if let logger = logger, logger.isLogging(.exit) {
                logger.log(.exit, msg: msg(),
                           functionName: functionName, lineNum: lineNum, fileName: fileName)
            }
            swiftLogger?.trace("\(msg())")
    }
    
    /// Indicates if a message with a specified type (`LoggerMessageType`) will be logged
    /// by some configured logger (i.e. will not be filtered out). This could be a Logger
    /// conforming to LoggerAPI, swift-log or both.
    ///
    /// Note that due to differences in the log levels defined by LoggerAPI and swift-log,
    /// their equivalence is mapped as follows:
    /// ```
    ///    LoggerAPI:     swift-log:
    ///    .error     ->  .error
    ///    .warning   ->  .warning
    ///    .info      ->  .notice
    ///    .verbose   ->  .info
    ///    .debug     ->  .debug
    ///    .entry     ->  .trace
    ///    .exit      ->  .trace
    /// ```
    ///
    /// For example, a swift-log Logger configured to log at the `.notice` level will log
    /// messages from LoggerAPI at a level of `.info` or higher.
    ///
    /// - Parameter level: The type of message (`LoggerMessageType`).
    ///
    /// - Returns: A Boolean indicating whether a message of the specified type
    ///           (`LoggerMessageType`) will be logged.
    public class func isLogging(_ level: LoggerMessageType) -> Bool {
        return isLoggingToLoggerAPI(level) || isLoggingToSwiftLog(level)
    }

    /// Indicates whether a LoggerAPI Logger is configured to log at the specified level.
    ///
    /// - Parameter level: The type of message (`LoggerMessageType`).
    ///
    /// - Returns: A Boolean indicating whether a message of the specified type
    ///           will be logged via the registered `LoggerAPI.Logger`.
    private class func isLoggingToLoggerAPI(_ level: LoggerMessageType) -> Bool {
        guard let logger = logger else {
            return false
        }
        return logger.isLogging(level)
    }

    /// Indicates whether a swift-log Logger is configured to log at the specified level.
    ///
    /// - Parameter level: The type of message (`LoggerMessageType`).
    ///
    /// - Returns: A Boolean indicating whether a message of the specified type
    ///            will be logged via the registered `Logging.Logger`.
    private class func isLoggingToSwiftLog(_ level: LoggerMessageType) -> Bool {
        guard let logger = swiftLogger else {
            return false
        }
        switch level {
        case .error:
            return logger.logLevel <= .error
        case .warning:
            return logger.logLevel <= .warning
        case .info:
            return logger.logLevel <= .notice
        case .verbose:
            return logger.logLevel <= .info
        case .debug:
            return logger.logLevel <= .debug
        case .entry, .exit:
            return logger.logLevel <= .trace
        }
    }
}

/// The type of a particular log message. It is passed with the message to be logged to the
/// actual logger implementation. It is also used to enable filtering of the log based
/// on the minimal type to log.
public enum LoggerMessageType: Int {
    /// Log message type for logging when entering into a function.
    case entry = 1
    /// Log message type for logging when exiting from a function.
    case exit = 2
    /// Log message type for logging a debugging message.
    case debug = 3
    /// Log message type for logging messages in verbose mode.
    case verbose = 4
    /// Log message type for logging an informational message.
    case info = 5
    /// Log message type for logging a warning message.
    case warning = 6
    /// Log message type for logging an error message.
    case error = 7
}
