// Copyright © 2024 Claus Jørgensen. All rights reserved.

import Foundation
import os

enum Logger {
    private static let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "", category: "Logging")

    static func info(_ message: String) {
        log(message, type: .info)
    }

    static func debug(_ message: String) {
        log(message, type: .debug)
    }

    static func error(_ message: String) {
        log(message, type: .error)
    }

    static func fault(_ message: String) {
        log(message, type: .fault)
    }

    private static func log(_ message: String, type: OSLogType) {
        os_log("%{public}@", log: Self.log, type: type, message)
    }
}
