import Foundation

protocol MonitorService {
    associatedtype DataType: Sendable
    func fetch() -> DataType
}
