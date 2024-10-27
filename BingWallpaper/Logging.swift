// Copyright © 2024 Claus Jørgensen. All rights reserved.

import Foundation

// swiftlint:disable:next convenience_type
struct Logger {
    nonisolated(unsafe) private static var destination = FileDestination()

    static func debug(_ message: String) {
        log("[DEBUG]", message)
    }

    static func info(_ message: String) {
        log("[INFO]", message)
    }

    static func error(_ message: String) {
        log("[ERROR]", message)
    }

    private static func log(_ category: String, _ message: String) {
        print("[\(Date())]", category, message)
        print("[\(Date())]", category, message, to: &destination)
    }
}

struct FileDestination: TextOutputStream {
    private let url: URL

    init() {
        url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BingWallpaper.log")

        if !FileManager.default.fileExists(atPath: url.path) {
            try? Data("[\(Date())] [INFO] Bing Wallpaper \(Bundle.main.shortVersionString)\n".utf8).write(to: url)
        }
    }

    mutating func write(_ string: String) {
        do {
            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
            handle.write(Data(string.utf8))
            handle.closeFile()
        } catch {
            print(error)
        }
    }
}
