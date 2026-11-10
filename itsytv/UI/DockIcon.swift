import AppKit

/// An optional Dock icon for Itsytv, a menu bar app (`LSUIElement`): a lasting way in for someone
/// whose menu bar icon is hidden. Clicking it reopens the app (`AppController.handleReopen`).
enum DockIcon {
    static let key = "showInDock"

    static var isOn: Bool { UserDefaults.standard.bool(forKey: key) }

    static func set(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: key)
        apply()
    }

    /// At launch and after a change.
    static func apply() {
        NSApp.setActivationPolicy(isOn ? .regular : .accessory)
    }
}
