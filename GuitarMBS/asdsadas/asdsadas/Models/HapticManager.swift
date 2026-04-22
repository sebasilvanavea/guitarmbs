import UIKit

/// Centralized haptic feedback helper.
enum HapticManager {

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // Convenience
    static func correct()   { notification(.success) }
    static func wrong()     { notification(.error) }
    static func tap()       { impact(.light) }
    static func beat()      { impact(.rigid) }
}
