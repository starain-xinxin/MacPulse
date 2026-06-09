import WidgetKit
import MacPulseShared

struct GPUEntry: TimelineEntry {
    let date: Date
    let gpu: GPUData
    let thermal: ThermalData

    static let placeholder = GPUEntry(
        date: Date(),
        gpu: GPUData(activeUsage: 0.45, gpuName: "Apple M4 Pro"),
        thermal: ThermalData(
            cpuTemperature: 45.0,
            gpuTemperature: 42.0,
            thermalPressure: .nominal
        )
    )
}

struct GPUWidgetProvider: TimelineProvider {
    let sharedData = SharedDataManager()

    func placeholder(in context: Context) -> GPUEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (GPUEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GPUEntry>) -> Void) {
        completion(Timeline(entries: [makeEntry()], policy: .atEnd))
    }

    private func makeEntry() -> GPUEntry {
        guard let snapshot = sharedData.readSnapshot() else { return .placeholder }
        return GPUEntry(
            date: snapshot.timestamp,
            gpu: snapshot.gpu,
            thermal: snapshot.thermal
        )
    }
}
