import Foundation

public enum ByteRateFormatter {
    public static func string(
        bytesPerSecond: UInt64,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let units = ["B/s", "KB/s", "MB/s", "GB/s", "TB/s"]
        var value = Double(bytesPerSecond)
        var unitIndex = 0

        while value >= 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = unitIndex == 0 ? 0 : 1

        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(number) \(units[unitIndex])"
    }
}
