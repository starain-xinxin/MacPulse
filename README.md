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
- **Top Processes** — Highest CPU and resident-memory consumers inside the CPU and Memory cards
- **Thermal Monitoring** — CPU temperature, system thermal pressure level
- **System Info** — Model, chip name, macOS version, uptime

### App Interfaces

| Interface | Description |
|-----------|-------------|
| **Dashboard Window** | Main window with a grid of metric cards, gauges, and sparklines |
| **Menu Bar** | MenuBarExtra showing key metrics at a glance |
| **Desktop Widgets** | 4 medium WidgetKit widgets — GPU, Network, CPU·RAM·Disk, and a split-view Top Processes widget — with second-level refresh while the app runs |
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

The main app runs outside App Sandbox so it can read system-wide process
statistics through `libproc`; the WidgetKit extension remains sandboxed and
only reads the shared snapshot.

## Roadmap

This is an early-stage build. The core monitoring infrastructure works, but there are known issues and many planned improvements:

### Known Issues


### Planned Features

- [ ] **History persistence** — Store metric history for longer-term sparkline/chart views
- [ ] **Notification alerts** — Optional alerts when CPU/memory/disk exceeds thresholds
- [ ] **Export / logging** — Export system metrics to CSV or JSON for analysis


## License

MIT

## Acknowledgments

- IOReport API usage inspired by [socpowerbuddy](https://github.com/BitesPotatoBacks/SocPowerBuddy) and [asitop](https://github.com/tlkh/asitop)
