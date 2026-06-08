import Foundation

enum CardType: String, CaseIterable, Identifiable, Codable {
    case cpu
    case memory
    case gpu
    case disk
    case network
    case battery

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cpu: return "CPU"
        case .memory: return "Memory"
        case .gpu: return "GPU"
        case .disk: return "Disk"
        case .network: return "Network"
        case .battery: return "Battery"
        }
    }

    static let defaultOrder: [CardType] = [.cpu, .memory, .gpu, .disk, .network, .battery]
}
