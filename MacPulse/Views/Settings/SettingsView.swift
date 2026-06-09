import SwiftUI
import ServiceManagement
import WidgetKit
import MacPulseShared

struct SettingsView: View {
    @Bindable var viewModel: DashboardViewModel

    @AppStorage(ModuleRefreshSettings.cpuPreferenceKey)
    private var cpuRefreshInterval = ModuleRefreshSettings.default.cpu
    @AppStorage(ModuleRefreshSettings.memoryPreferenceKey)
    private var memoryRefreshInterval = ModuleRefreshSettings.default.memory
    @AppStorage(ModuleRefreshSettings.diskPreferenceKey)
    private var diskRefreshInterval = ModuleRefreshSettings.default.disk
    @AppStorage(ModuleRefreshSettings.networkPreferenceKey)
    private var networkRefreshInterval = ModuleRefreshSettings.default.network
    @AppStorage(ModuleRefreshSettings.batteryPreferenceKey)
    private var batteryRefreshInterval = ModuleRefreshSettings.default.battery
    @AppStorage(ModuleRefreshSettings.gpuPreferenceKey)
    private var gpuRefreshInterval = ModuleRefreshSettings.default.gpu
    @AppStorage(ModuleRefreshSettings.processesPreferenceKey)
    private var processesRefreshInterval = ModuleRefreshSettings.default.processes
    @AppStorage("temperatureUnit") private var temperatureUnit: String = TemperatureUnit.celsius.rawValue
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage(DockVisibilityController.preferenceKey) private var showDockIcon: Bool = false
    @AppStorage(AppLanguage.preferenceKey) private var appLanguage = AppLanguage.system.rawValue
    private let sharedDataManager = SharedDataManager()

    var body: some View {
        Form {
            Section("General") {
                Picker("Language", selection: $appLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(languageLabel(language)).tag(language.rawValue)
                    }
                }
                .onChange(of: appLanguage) {
                    try? sharedDataManager.setSharedAppLanguage(
                        AppLanguage(rawValue: appLanguage) ?? .system
                    )
                    WidgetCenter.shared.reloadAllTimelines()
                }

                Picker("Temperature Unit", selection: $temperatureUnit) {
                    ForEach(TemperatureUnit.allCases, id: \.rawValue) { unit in
                        Text(unit.label).tag(unit.rawValue)
                    }
                }

                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }

                Toggle("Show in Dock", isOn: $showDockIcon)
                    .onChange(of: showDockIcon) { _, newValue in
                        DockVisibilityController.apply(showDockIcon: newValue)
                    }
            }

            Section {
                RefreshIntervalRow(title: "CPU", interval: $cpuRefreshInterval)
                    .onChange(of: cpuRefreshInterval) { _, value in
                        viewModel.monitor.updateRefreshInterval(value, for: .cpu)
                    }
                RefreshIntervalRow(title: "Memory", interval: $memoryRefreshInterval)
                    .onChange(of: memoryRefreshInterval) { _, value in
                        viewModel.monitor.updateRefreshInterval(value, for: .memory)
                    }
                RefreshIntervalRow(title: "Disk", interval: $diskRefreshInterval)
                    .onChange(of: diskRefreshInterval) { _, value in
                        viewModel.monitor.updateRefreshInterval(value, for: .disk)
                    }
                RefreshIntervalRow(title: "Network", interval: $networkRefreshInterval)
                    .onChange(of: networkRefreshInterval) { _, value in
                        viewModel.monitor.updateRefreshInterval(value, for: .network)
                    }
                RefreshIntervalRow(title: "Battery", interval: $batteryRefreshInterval)
                    .onChange(of: batteryRefreshInterval) { _, value in
                        viewModel.monitor.updateRefreshInterval(value, for: .battery)
                    }
                RefreshIntervalRow(title: "GPU", interval: $gpuRefreshInterval)
                    .onChange(of: gpuRefreshInterval) { _, value in
                        viewModel.monitor.updateRefreshInterval(value, for: .gpu)
                    }
                RefreshIntervalRow(title: "Top Processes", interval: $processesRefreshInterval)
                    .onChange(of: processesRefreshInterval) { _, value in
                        viewModel.monitor.updateRefreshInterval(value, for: .processes)
                    }
            } header: {
                Text("Refresh Rates")
            } footer: {
                Text("Widgets use the same refresh interval as the dashboard.")
            }

            Section("About") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 570)
        .onAppear {
            try? sharedDataManager.setSharedAppLanguage(
                AppLanguage(rawValue: appLanguage) ?? .system
            )
        }
    }

    private func languageLabel(_ language: AppLanguage) -> LocalizedStringKey {
        switch language {
        case .system: return "System Default"
        case .english: return "English"
        case .simplifiedChinese: return "Simplified Chinese"
        }
    }
}

private struct RefreshIntervalRow: View {
    let title: LocalizedStringKey
    @Binding var interval: Double

    var body: some View {
        LabeledContent(title) {
            Stepper(
                value: $interval,
                in: ModuleRefreshSettings.minimumInterval...ModuleRefreshSettings.maximumInterval,
                step: 1
            ) {
                Text("\(Int(interval))s")
                    .monospacedDigit()
                    .frame(minWidth: 30, alignment: .trailing)
            }
            .fixedSize()
        }
    }
}
