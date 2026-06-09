import SwiftUI
import MacPulseShared

struct WidgetLanguageModifier: ViewModifier {
    private let sharedDataManager = SharedDataManager()

    func body(content: Content) -> some View {
        content.environment(
            \.locale,
            sharedDataManager.sharedAppLanguage.locale
        )
    }
}
