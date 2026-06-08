import Foundation

enum Formatters {
    static func byteCount(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    static func byteCount(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .memory)
    }

    static func percentage(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }

    static func percentageInt(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }

    static func temperature(_ celsius: Double, useFahrenheit: Bool = false) -> String {
        if useFahrenheit {
            return String(format: "%.1f\u{00B0}F", celsius * 9 / 5 + 32)
        }
        return String(format: "%.1f\u{00B0}C", celsius)
    }

    static func bytesPerSecond(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.allowedUnits = [.useAll]
        return formatter.string(fromByteCount: Int64(bytes)) + "/s"
    }

    static func duration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    static func timeRemaining(_ interval: TimeInterval?) -> String? {
        guard let interval, interval > 0 else { return nil }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
