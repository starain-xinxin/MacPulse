import SwiftUI

@main
struct MacPulseApp: App {
    @State private var viewModel = DashboardViewModel()

    var body: some Scene {
        WindowGroup {
            DashboardView(viewModel: viewModel)
        }
        .defaultSize(width: 720, height: 640)

        MenuBarExtra("MacPulse", systemImage: "gauge.with.dots.needle.33percent") {
            MenuBarView(viewModel: viewModel)
        }

        Settings {
            SettingsView()
        }
    }
}
