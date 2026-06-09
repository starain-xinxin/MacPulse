import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Bindable var viewModel: DashboardViewModel

    @AppStorage("pollingInterval") private var pollingInterval: Double = AppConstants.defaultPollingInterval
    @AppStorage("temperatureUnit") private var temperatureUnit: String = TemperatureUnit.celsius.rawValue
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage(DockVisibilityController.preferenceKey) private var showDockIcon: Bool = false

    var body: some View {
        Form {
            Section("General") {
                Picker("Polling Interval", selection: $pollingInterval) {
                    ForEach(PollingInterval.allCases, id: \.rawValue) { interval in
                        Text(interval.label).tag(interval.rawValue)
                    }
                }
                .onChange(of: pollingInterval) { _, newValue in
                    viewModel.monitor.updatePollingInterval(newValue)
                }

                Picker("Temperature Unit", selection: $temperatureUnit) {
                    ForEach(TemperatureUnit.allCases, id: \.rawValue) { unit in
                        Text(unit.rawValue).tag(unit.rawValue)
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

            Section("About") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 290)
    }
}
