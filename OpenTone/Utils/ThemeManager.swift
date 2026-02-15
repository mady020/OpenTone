import UIKit

/// Manages the app-wide theme preference (dark, light, or system default).
/// Persists choice to UserDefaults and applies via `overrideUserInterfaceStyle` on all connected scenes.
final class ThemeManager {

    static let shared = ThemeManager()

    // MARK: - Theme Enum

    enum Theme: Int, CaseIterable {
        case system = 0
        case light  = 1
        case dark   = 2

        var title: String {
            switch self {
            case .system: return "System Default"
            case .light:  return "Light"
            case .dark:   return "Dark"
            }
        }

        var iconName: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light:  return "sun.max.fill"
            case .dark:   return "moon.fill"
            }
        }

        var userInterfaceStyle: UIUserInterfaceStyle {
            switch self {
            case .system: return .unspecified
            case .light:  return .light
            case .dark:   return .dark
            }
        }
    }

    // MARK: - Storage Key

    private let themeKey = "app_theme_preference"

    // MARK: - Current Theme

    var currentTheme: Theme {
        get {
            let raw = UserDefaults.standard.integer(forKey: themeKey)
            return Theme(rawValue: raw) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: themeKey)
            applyTheme(newValue)
        }
    }

    // MARK: - Init

    private init() {}

    // MARK: - Apply

    /// Call this once at app launch (in SceneDelegate or AppDelegate) to apply the stored preference.
    func applyStoredTheme() {
        applyTheme(currentTheme)
    }

    /// Applies the given theme to all connected window scenes.
    func applyTheme(_ theme: Theme) {
        let style = theme.userInterfaceStyle
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                UIView.animate(withDuration: 0.25) {
                    window.overrideUserInterfaceStyle = style
                }
            }
        }
    }
}
