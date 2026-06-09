import SwiftUI
import MacPulseShared

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DockVisibilityController.applySavedPreference()
    }
}

@main
struct MacPulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var viewModel = DashboardViewModel()
    @AppStorage(
        AppLanguage.preferenceKey,
        store: AppLanguage.sharedDefaults
    ) private var appLanguage = AppLanguage.system.rawValue

    private var locale: Locale {
        (AppLanguage(rawValue: appLanguage) ?? .system).locale
    }

    var body: some Scene {
        WindowGroup(id: AppWindow.dashboardID) {
            DashboardView(viewModel: viewModel)
                .environment(\.locale, locale)
        }
        .defaultSize(width: 720, height: 640)

        MenuBarExtra("MacPulse", systemImage: "gauge.with.dots.needle.33percent") {
            MenuBarView(viewModel: viewModel)
                .environment(\.locale, locale)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: viewModel)
                .environment(\.locale, locale)
        }
    }
}
