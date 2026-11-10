import Foundation

/// When the welcome shows. Itsytv has no window and – unless chosen – no Dock icon, so a new user
/// whose menu bar icon is hidden has no way in at all:
/// - a new user sees it on the first launch
/// - it comes back on every launch while the icon stays hidden, nothing is paired yet and Itsytv
///   isn't in the Dock – the hidden-icon welcome offers no way to dismiss it without a fix
/// - someone updating who already uses the app never sees it: a hidden icon is then their choice
struct WelcomeGate {
    static let shownKey = "welcomeShown"

    let defaults: UserDefaults

    func shouldShow(hasUsedApp: Bool, iconHidden: Bool, inDock: Bool) -> Bool {
        let firstTime = !defaults.bool(forKey: Self.shownKey)
        defaults.set(true, forKey: Self.shownKey)
        guard !hasUsedApp else { return false }
        return firstTime || (iconHidden && !inDock)
    }
}
