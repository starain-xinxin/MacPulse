# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MacPulse is a native macOS system monitor for Apple Silicon built with SwiftUI. It provides real-time system metrics through a dashboard window, menu bar extra, and desktop widgets with minimal overhead.

**Target platform:** macOS 15.0+ on Apple Silicon (M1/M2/M3/M4)

**Zero third-party dependencies** — uses only Apple frameworks: SwiftUI, WidgetKit, IOKit, Network, ServiceManagement, CoreLocation, CoreWLAN.

## Building & Running

```bash
# Open the project
open MacPulse.xcodeproj

# Build and run from Xcode
# Select the "MacPulse" scheme, then Cmd+R
```

**Important:** The project uses a local Swift package (`MacPulseShared`) that Xcode manages automatically. No package resolution commands are needed.

### Testing

```bash
# Run tests from Xcode
# Select "MacPulse" scheme, then Cmd+U

# Or use xcodebuild
xcodebuild test -scheme MacPulse -destination 'platform=macOS'
```

## Architecture

### Three-Target Structure

1. **MacPulse.app** — Main application with dashboard, menu bar, settings
2. **MacPulseWidgets** — WidgetKit extension providing 6 desktop widgets
3. **MacPulseShared** — Local Swift package shared between app and widgets

### Data Flow

```
Monitor Services (poll system APIs every 1s)
    ↓
SystemMonitor (orchestrates all monitors, assembles SystemSnapshot)
    ↓
├─→ DashboardViewModel (@Observable) → SwiftUI Views
└─→ SharedDataManager → App Group JSON → Widget TimelineProviders
```

**Key mechanism:** The app writes a `SystemSnapshot` to the App Group (`group.starain.MacPulse`) on every poll and calls `WidgetCenter.shared.reloadAllTimelines()`. This enables **second-level widget updates** while the app runs (foreground reloads bypass WidgetKit's background budget). After the app quits, widgets fall back to OS background refresh rates.

### Monitor Services

All monitors conform to `MonitorService` protocol:

```swift
protocol MonitorService {
    associatedtype DataType: Sendable
    func fetch() -> DataType
}
```

**Services in `MacPulse/Services/`:**
- `CPUMonitor` — `host_processor_info()` for per-core and overall CPU usage
- `MemoryMonitor` — `host_statistics64()` for memory stats
- `DiskMonitor` — `FileManager` volume enumeration
- `NetworkMonitor` — `getifaddrs()` for traffic bytes, CoreWLAN for SSID, HTTP for public IP/geo
- `BatteryMonitor` — `IOPSCopyPowerSourcesInfo` + IOKit registry
- `GPUMonitor` — IOAccelerator performance statistics with IOReport residency fallback
- `ThermalMonitor` — IOReport for CPU temperature and thermal pressure
- `SystemInfoProvider` — `sysctlbyname()` for chip model, OS version, uptime

`SystemMonitor` (`MacPulse/Services/SystemMonitor.swift`) coordinates all services, runs a Timer at the configured polling interval, and writes snapshots to the App Group.

### IOReport C API

MacPulse uses the **undocumented but stable IOReport API** from IOKit to access GPU and thermal data not exposed through public Swift APIs.

**Setup:**
- `MacPulse/MacPulse-Bridging-Header.h` declares IOReport functions with proper `CF_RETURNS_RETAINED` annotations
- `libIOReport` is linked in build settings (implicitly available in IOKit)
- `GPUMonitor.swift` and `ThermalMonitor.swift` use IOReport channels (`"GPU Stats"` group)

**Pattern:**
1. Create subscription: `IOReportCopyChannelsInGroup("GPU Stats", ...) → IOReportCreateSubscription(...)`
2. Sample deltas: `IOReportCreateSamples(...)` → `IOReportCreateSamplesDelta(prev, current, ...)`
3. Iterate channels: `IOReportIterate(delta) { channel in ... }`

### Shared Data (App Group)

**App Group ID:** `group.starain.MacPulse`

**Shared between:**
- `MacPulse.app` (bundle ID: `starain.MacPulse`)
- `MacPulseWidgets` (bundle ID: `starain.MacPulse.MacPulseWidgets`)

**Files in App Group container:**
- `snapshot.json` — Latest `SystemSnapshot` (written by app, read by widgets)
- `UserDefaults(suiteName:)` keys:
  - `lastUpdate` — Timestamp of last snapshot write
  - `pollingInterval` — Shared polling rate (seconds); app and widgets sync from this

**SharedDataManager** (`MacPulseShared/Sources/MacPulseShared/SharedDataManager.swift`) handles read/write. It's instantiated in both the app's `SystemMonitor` and each widget's `TimelineProvider`.

### Widget Architecture

**6 Widgets in `MacPulseWidgets/`:**
- CPUWidget, MemoryWidget, BatteryWidget, NetworkWidget, SystemOverviewWidget, SystemStatsWidget

**Structure per widget:**
- `Providers/<Name>Provider.swift` — `TimelineProvider` reading from App Group
- `Widgets/<Name>Widget.swift` — Widget configuration with `.supportedFamilies`
- `Views/<Name>WidgetView.swift` — SwiftUI views for each size family

**Timeline policy:** `.atEnd` — request a new timeline as soon as the current entry is displayed. This pairs with the app's per-poll `WidgetCenter.shared.reloadAllTimelines()` call to achieve real-time updates while the app is running.

**History in widgets:** `SystemSnapshot.history` (type `MetricHistory`) carries recent sparkline samples (`cpuHistory`, `memoryHistory`, `downloadHistory`, `uploadHistory`) so widgets render the same charts as the dashboard. Max 60 samples (`AppConstants.sparklineMaxSamples`).

## Common Patterns

### Adding a New Monitor

1. Create `<Name>Monitor.swift` in `MacPulse/Services/`
2. Conform to `MonitorService` with `associatedtype DataType = <Name>Data`
3. Add corresponding `<Name>Data` struct in `MacPulseShared/Sources/MacPulseShared/Models/` (must be `Codable` and `Sendable`)
4. Instantiate the monitor in `SystemMonitor` and call `fetch()` in the `poll()` method
5. Add the data to `SystemSnapshot` in `MacPulseShared/Sources/MacPulseShared/Models/SystemSnapshot.swift`

### Adding a New Widget

1. Create three files in `MacPulseWidgets/`:
   - `Providers/<Name>Provider.swift` — timeline provider
   - `Widgets/<Name>Widget.swift` — widget configuration
   - `Views/<Name>WidgetView.swift` — views for size families
2. Register the widget in `MacPulseWidgetsBundle.swift`
3. The provider reads from `SharedDataManager().readSnapshot()` and uses `.atEnd` policy
4. Extract relevant data from `SystemSnapshot` and pass to the view

### Widget Discovery Issue (Fixed)

If widgets don't appear in the widget picker, verify `MacPulseWidgets-Info.plist` (or the target's Info.plist) contains:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
</dict>
```

Without this, macOS never registers the extension as a WidgetKit provider.

## Key Technical Constraints

### Apple Silicon Only

The app uses chip-specific APIs:
- IOReport GPU Stats channels are M-series specific
- Thermal sensor paths vary by chip generation
- `sysctlbyname("machdep.cpu.brand_string")` extracts chip name (M1/M2/M3/M4)

Do not attempt to support Intel Macs — the monitor infrastructure assumes Apple Silicon.

### macOS 15.0+ Required

- Uses Swift 6 language mode (`@Observable` macro, strict concurrency)
- `MacPulseShared/Package.swift` declares `.macOS(.v15)`
- WidgetKit APIs like `.containerBackground` require macOS 14+, this project targets 15+

### Concurrency & Sendability

- All monitor services are `Sendable` (some use `@unchecked Sendable` due to C API types like `CFDictionary`)
- `SystemMonitor.poll()` runs monitors on `Task.detached` to avoid blocking `@MainActor`
- `SystemSnapshot` and all data model structs are `Sendable` (value types with `Codable`)

### SSID Requires Location Authorization

On macOS Sonoma+, reading Wi-Fi SSID via CoreWLAN requires `CoreLocation` authorization. `LocationManager` requests `whenInUse` authorization at app startup, and `NetworkMonitor` checks `locationManager.isAuthorized` before calling `CWWiFiClient.sharedWiFiClient()?.interface()?.ssid()`.

## Known Issues & Debugging

### GPU Usage Sampling

`GPUMonitor` reads `PerformanceStatistics` from the `IOAccelerator` service, preferring `Device Utilization %` and supporting alternate driver keys. IOReport is retained as a fallback and samples only the `GPU Performance States` / `GPUPH` channel.

When changing the fallback, keep the channel dictionary separate from the subscription object when calling `IOReportCreateSamples`. GPU Stats contains many unrelated state channels, so do not aggregate every state-formatted channel in the group.

### CPU Temperature Not Displaying

IOKit sensor paths vary across chip generations. `ThermalMonitor` may need per-chip registry key mapping.

**To debug:**
1. Use `ioreg -l` in Terminal to find temperature sensors for your chip
2. Look for `AppleARMIODevice` entries with "temperature" properties
3. Update `ThermalMonitor.swift` with correct registry paths

## Development Workflow

### Polling Interval Changes

The polling interval setting (`SettingsView`) writes to **both** `UserDefaults.standard` (local) and the App Group via `SharedDataManager.setSharedPollingInterval(_:)`. The running `SystemMonitor` calls `reconcileSharedInterval()` on every poll to pick up changes.

Widgets can also expose the polling rate in their configuration intent (not currently implemented) — if implemented, the same `SharedDataManager` mechanism keeps app and widgets in sync.

### Dashboard Card Reordering

Dashboard cards are drag-and-drop reorderable. `DashboardViewModel.cardOrder` persists to `UserDefaults` (local, not App Group) as JSON-encoded `[CardType]`. Only the **app** needs this — widgets don't render a dashboard.

### Adding System Info Fields

To add a new field to the system info display:
1. Add the property to `SystemInfoData` in `MacPulseShared/Sources/MacPulseShared/Models/` (ensure `Codable`)
2. Fetch the value in `SystemInfoProvider.fetch()`
3. Update relevant views (`Dashboard/SystemCardView.swift` if it exists, or add a new card)

## README Maintenance

**Always update README.md** when:
- Adding or removing features
- Fixing a known issue (move it from "Known Issues" to resolved, or remove the bullet)
- Changing build requirements or architecture

The README is the user-facing documentation; keep it in sync with the code.

## Git Workflow

- Pull before starting development (`git pull`)
- Create feature branches from `main` for non-trivial work
- Commit messages should be descriptive; multi-line if needed
- Use `.gitignore` to exclude `xcuserdata`, `.DS_Store`, build artifacts
