import SwiftUI
import MacPulseShared

struct WidgetLanguageModifier: ViewModifier {
    @AppStorage(
        AppLanguage.preferenceKey,
        store: AppLanguage.sharedDefaults
    ) private var appLanguage = AppLanguage.system.rawValue

    func body(content: Content) -> some View {
        content.environment(
            \.locale,
            (AppLanguage(rawValue: appLanguage) ?? .system).locale
        )
    }
}
