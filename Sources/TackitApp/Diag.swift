import Foundation
import os

enum Diag {
    private static let logger = Logger(subsystem: "com.example.tackit", category: "m0")
    private static let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent("Library/Logs/tackit-m0.log")

    static func log(_ message: String) {
        logger.notice("\(message, privacy: .public)")
        let line = "[\(timestamp())] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { try? handle.close() }
            handle.seekToEndOfFile()
            handle.write(data)
        } else {
            try? data.write(to: fileURL)
        }
    }

    private static func timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
}
