import WidgetKit
import MacPulseShared

struct BatteryWidgetEntry: TimelineEntry {
    let date: Date
    let batteryData: BatteryData?

    static let placeholder = BatteryWidgetEntry(
        date: Date(),
        batteryData: BatteryData(
            chargeLevel: 0.87,
            isCharging: false,
            isPluggedIn: false,
            cycleCount: 142,
            healthPercentage: 0.94,
            maxCapacity: 5100,
            designCapacity: 5400
        )
    )
}

struct BatteryWidgetProvider: TimelineProvider {
    let sharedData = SharedDataManager()

    func placeholder(in context: Context) -> BatteryWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BatteryWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BatteryWidgetEntry>) -> Void) {
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> BatteryWidgetEntry {
        if let snapshot = sharedData.readSnapshot() {
            return BatteryWidgetEntry(date: snapshot.timestamp, batteryData: snapshot.battery)
        }
        return .placeholder
    }
}
