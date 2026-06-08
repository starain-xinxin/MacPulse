import Foundation

/// Recent metric history shared with the widget extension so widgets can draw
/// the same sparklines as the dashboard. Each array is capped to a small number
/// of samples (see SystemMonitor) to keep the App Group JSON tiny.
public struct MetricHistory: Codable, Sendable {
    public var cpu: [Double]
    public var memory: [Double]
    public var gpu: [Double]
    public var download: [UInt64]
    public var upload: [UInt64]

    public init(
        cpu: [Double] = [],
        memory: [Double] = [],
        gpu: [Double] = [],
        download: [UInt64] = [],
        upload: [UInt64] = []
    ) {
        self.cpu = cpu
        self.memory = memory
        self.gpu = gpu
        self.download = download
        self.upload = upload
    }

    public static let empty = MetricHistory()
}
