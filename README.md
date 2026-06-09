# MacPulse

A lightweight, native macOS system monitor for Apple Silicon MacBooks.

Built with SwiftUI and WidgetKit. No Electron, no web views — just pure Swift calling macOS system APIs directly, keeping CPU and memory overhead minimal.

## Features

- **CPU Monitoring** — Overall and per-core usage with real-time sparkline charts
- **Memory Monitoring** — Used/free/active/wired/compressed breakdown, memory pressure, swap usage
- **Disk Monitoring** — Capacity and usage for all mounted local volumes
- **Network Monitoring** — Upload/download speed, total traffic, interface type, local IP, Wi-Fi SSID, public IP with geolocation
- **Battery Monitoring** — Charge level, health percentage, cycle count, temperature, time remaining
- **GPU Monitoring** — Active usage via IOReport API (Apple Silicon integrated GPU)
- **Thermal Monitoring** — CPU temperature, system thermal pressure level
- **System Info** — Model, chip name, macOS version, uptime

### App Interfaces

| Interface | Description |
|-----------|-------------|
| **Dashboard Window** | Main window with a grid of metric cards, gauges, and sparklines |
| **Menu Bar** | MenuBarExtra showing key metrics at a glance |
| **Desktop Widgets** | 6 WidgetKit widgets (CPU, Memory, Battery, Network, System Overview, CPU·RAM·Disk) with sparkline charts and second-level refresh while the app runs |
| **Settings** | Polling interval (default 1s, applied live), temperature unit, launch at login |

## Screenshots

> Screenshots will be added after the UI is stabilized.

## Requirements

- macOS 15.0+
- Apple Silicon (M1/M2/M3/M4 series)
- Xcode 16.0+ to build

## Building

```bash
git clone https://github.com/starain-xinxin/MacPulse.git
cd MacPulse
open MacPulse.xcodeproj
```

Select the **MacPulse** scheme, then `Cmd+R` to build and run.

The project has zero third-party dependencies — it uses only Apple frameworks:
- SwiftUI, WidgetKit, IOKit, Network, ServiceManagement, CoreLocation, CoreWLAN

## Architecture

```
MacPulse.app
├── Services/          # System API monitors (CPU, Memory, Disk, Network, Battery, GPU, Thermal)
├── ViewModels/        # @Observable view models driving the UI
├── Views/             # SwiftUI dashboard cards, components, menu bar, settings
└── Utilities/         # Formatters, constants

MacPulseShared/        # Local Swift package shared between app and widget extension
├── Models/            # Codable data models (SystemSnapshot, CPUData, MemoryData, etc.)
└── SharedDataManager  # App Group read/write for widget data sharing

MacPulseWidgets/       # WidgetKit extension
├── Providers/         # Timeline providers reading from App Group
├── Widgets/           # Widget configurations
└── Views/             # Widget views for each size family
```

**Data flow:** Monitors poll system APIs at the configured interval (default 1s, shared with widgets via the App Group) → SystemMonitor assembles a `SystemSnapshot` → Dashboard UI updates via `@Observable` → Snapshot is written to App Group JSON every poll → Widgets read it via TimelineProvider.

**Key technical details:**
- IOAccelerator performance statistics with IOReport residency fallback for GPU usage
- IOReport C API (via bridging header + `libIOReport`) for GPU residency and thermal data
- `host_processor_info()` / `host_statistics64()` for CPU and memory
- `getifaddrs()` for network traffic bytes and local IPs
- `IOPSCopyPowerSourcesInfo` + IOKit registry for battery details
- App Group (`group.starain.MacPulse`) for widget data sharing

## Roadmap

This is an early-stage build. The core monitoring infrastructure works, but there are known issues and many planned improvements:

### Known Issues

- [x] ~~Desktop widgets cannot be added~~ (Fixed: the widget extension's `Info.plist` was missing the `NSExtension` / `NSExtensionPointIdentifier = com.apple.widgetkit-extension` key, so macOS never registered it as a WidgetKit provider)
- [x] ~~Dashboard card layout does not adapt well to different window sizes; cards are not draggable/reorderable~~ (Fixed: masonry layout + drag-and-drop)
- [x] ~~Public IP / geolocation not displaying~~ (Fixed: migrated to HTTPS endpoint with `success`/error handling — cleartext HTTP was blocked by App Transport Security)
- [x] ~~Only local IP is shown; Wi-Fi SSID name is not retrieved~~ (Fixed: SSID via CoreWLAN, gated by CoreLocation authorization required on macOS Sonoma+)
- [x] ~~GPU usage always reads 0%~~ (Fixed: read IOAccelerator utilization with corrected IOReport performance-state sampling as fallback)
- [ ] CPU temperature may not display (IOKit sensor paths vary across M1/M2/M3/M4 models)

### Planned Features

- [ ] **Top processes** — Show top CPU/memory consuming processes per metric card (via `sysctl` / `proc_pidinfo`)
- [x] ~~**Network details**~~ — Wi-Fi SSID display (CoreWLAN), public IP with geolocation (HTTPS), CoreLocation authorization to unlock SSID
- [x] ~~**Draggable dashboard**~~ — Cards are now drag-and-drop reorderable with persisted order
- [x] ~~**Responsive layout**~~ — Custom masonry layout adapts to window width
- [ ] **History persistence** — Store metric history for longer-term sparkline/chart views
- [x] ~~**GPU monitoring fix**~~ — Use IOAccelerator utilization across Apple Silicon generations and corrected IOReport GPU performance-state sampling as fallback
- [ ] **Temperature sensors** — Map correct IOKit/IOHIDSensor paths for each Apple Silicon chip variant
- [x] ~~**Widget refresh**~~ — Widgets read App Group data and now update at **second-level cadence while the app runs**: the app writes a snapshot and reloads timelines every poll, and providers use the `.atEnd` policy. Foreground/active reloads bypass WidgetKit's background budget (after a full quit, the OS background rate applies). Widgets now also show dashboard-style sparkline charts.
- [x] ~~**Adjustable refresh rate**~~ — Polling interval setting is now wired to the live monitor (default **1s**; the picker previously had no effect)
- [ ] **Notification alerts** — Optional alerts when CPU/memory/disk exceeds thresholds
- [ ] **Export / logging** — Export system metrics to CSV or JSON for analysis
- [ ] **Localization** — Chinese (Simplified) and English UI

## License

MIT

## Acknowledgments

- IOReport API usage inspired by [socpowerbuddy](https://github.com/BitesPotatoBacks/SocPowerBuddy) and [asitop](https://github.com/tlkh/asitop)
