import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DockVisibilityController.applySavedPreference()
    }
}

@main
struct MacPulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var viewModel = DashboardViewModel()

    var body: some Scene {
        WindowGroup(id: AppWindow.dashboardID) {
            DashboardView(viewModel: viewModel)
        }
        .defaultSize(width: 720, height: 640)

        MenuBarExtra("MacPulse", systemImage: "gauge.with.dots.needle.33percent") {
            MenuBarView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: viewModel)
        }
    }
}
