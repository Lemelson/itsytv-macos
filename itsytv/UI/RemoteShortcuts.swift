import SwiftUI
import Carbon.HIToolbox
import ItsytvCore

/// Every keyboard shortcut of the remote panel. The panel's key handler, the
/// on-remote hints and the Keyboard Shortcuts window all read this one table;
/// the keys themselves can be changed in the Keyboard Shortcuts window.
enum RemoteShortcut: String, CaseIterable, Identifiable {
    case up, down, left, right, select, back, home
    case playPause, volumeUp, volumeDown, mute
    case keyboard, appSearch, close

    var id: String { rawValue }

    var defaultKeys: ShortcutKeys {
        let command = NSEvent.ModifierFlags.command.rawValue
        let shift = NSEvent.ModifierFlags.shift.rawValue
        return switch self {
        case .up: ShortcutKeys(modifiers: 0, keyCode: UInt16(kVK_UpArrow))
        case .down: ShortcutKeys(modifiers: 0, keyCode: UInt16(kVK_DownArrow))
        case .left: ShortcutKeys(modifiers: 0, keyCode: UInt16(kVK_LeftArrow))
        case .right: ShortcutKeys(modifiers: 0, keyCode: UInt16(kVK_RightArrow))
        case .select: ShortcutKeys(modifiers: 0, keyCode: UInt16(kVK_Return))
        case .back: ShortcutKeys(modifiers: 0, keyCode: UInt16(kVK_Escape))
        case .home: ShortcutKeys(modifiers: 0, keyCode: UInt16(kVK_Delete))
        case .playPause: ShortcutKeys(modifiers: 0, keyCode: UInt16(kVK_Space))
        case .volumeUp: ShortcutKeys(modifiers: 0, keyCode: UInt16(kVK_ANSI_Equal))
        case .volumeDown: ShortcutKeys(modifiers: 0, keyCode: UInt16(kVK_ANSI_Minus))
        case .mute: ShortcutKeys(modifiers: command | shift, keyCode: UInt16(kVK_ANSI_M))
        case .keyboard: ShortcutKeys(modifiers: command, keyCode: UInt16(kVK_ANSI_K))
        case .appSearch: ShortcutKeys(modifiers: command, keyCode: UInt16(kVK_ANSI_F))
        case .close: ShortcutKeys(modifiers: command, keyCode: UInt16(kVK_ANSI_W))
        }
    }

    /// Current keys (custom or default); nil when the user cleared the shortcut.
    var keys: ShortcutKeys? { ShortcutSettings.shared.keys(for: self) }

    /// Key caps as drawn on screen, one string per cap.
    var keyCaps: [String] { keys.map(ShortcutKeys.caps) ?? ["—"] }

    var label: String { keyCaps.joined() }

    var title: String {
        switch self {
        case .up: "Up"
        case .down: "Down"
        case .left: "Left"
        case .right: "Right"
        case .select: "Select"
        case .back: "Back"
        case .home: "TV / Home"
        case .playPause: "Play / Pause"
        case .volumeUp: "Volume up"
        case .volumeDown: "Volume down"
        case .mute: "Mute"
        case .keyboard: "Type on Apple TV"
        case .appSearch: "Search apps"
        case .close: "Close remote"
        }
    }

    /// ⌘ shortcuts also work while a text field has focus.
    var usesCommand: Bool { keys?.modifierFlags.contains(.command) ?? false }

    /// Held down, these do something different from a click (Back → Home screen,
    /// TV → Control Center, Select → context menu), so key repeat is not forwarded.
    var hasHoldAction: Bool {
        switch self {
        case .back, .home, .select, .playPause: true
        default: false
        }
    }

    /// The Apple TV button a plain key presses; nil for app-level actions.
    var companionButton: CompanionButton? {
        switch self {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .select: .select
        case .back: .menu
        case .home: .home
        case .playPause: .playPause
        case .volumeUp: .volumeUp
        case .volumeDown: .volumeDown
        case .mute, .keyboard, .appSearch, .close: nil
        }
    }

    static let groups: [(title: String, items: [RemoteShortcut])] = [
        ("Navigation", [.up, .down, .left, .right, .select, .back, .home]),
        ("Playback", [.playPause, .volumeUp, .volumeDown, .mute]),
        ("Remote", [.keyboard, .appSearch, .close]),
    ]

    static func match(_ event: NSEvent) -> RemoteShortcut? {
        let pressed = ShortcutKeys(event: event)
        if let shortcut = allCases.first(where: { $0.keys == pressed }) {
            return shortcut
        }
        // ⌘H has always closed the remote too; keep it while ⌘W is the default.
        if pressed == ShortcutKeys(modifiers: NSEvent.ModifierFlags.command.rawValue, keyCode: UInt16(kVK_ANSI_H)),
           close.keys == close.defaultKeys {
            return .close
        }
        return nil
    }
}

// MARK: - Custom keys

/// User-chosen keys for the remote shortcuts, stored in UserDefaults.
@Observable
final class ShortcutSettings {
    static let shared = ShortcutSettings()

    private static let storageKey = "customRemoteShortcuts"
    /// Stored for a shortcut the user cleared (assigned its keys elsewhere).
    private static let unassigned = ShortcutKeys(modifiers: 0, keyCode: .max)

    /// Overrides keyed by `RemoteShortcut.rawValue`; defaults are not stored.
    private var custom: [String: ShortcutKeys]

    /// The shortcut whose new keys are being recorded in the shortcuts window.
    var recording: RemoteShortcut?

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let stored = try? JSONDecoder().decode([String: ShortcutKeys].self, from: data) {
            custom = stored
        } else {
            custom = [:]
        }
    }

    func keys(for shortcut: RemoteShortcut) -> ShortcutKeys? {
        let keys = custom[shortcut.rawValue] ?? shortcut.defaultKeys
        return keys == Self.unassigned ? nil : keys
    }

    func isCustomized(_ shortcut: RemoteShortcut) -> Bool {
        custom[shortcut.rawValue] != nil
    }

    var hasCustomizations: Bool { !custom.isEmpty }

    /// Gives `keys` to `shortcut`. A shortcut that already had those keys takes
    /// over the old keys of `shortcut`, so nothing ends up with two meanings.
    func set(_ keys: ShortcutKeys, for shortcut: RemoteShortcut) {
        let previous = self.keys(for: shortcut) ?? Self.unassigned
        if let other = RemoteShortcut.allCases.first(where: { $0 != shortcut && self.keys(for: $0) == keys }) {
            assign(previous, to: other)
        }
        assign(keys, to: shortcut)
        save()
    }

    func reset(_ shortcut: RemoteShortcut) {
        set(shortcut.defaultKeys, for: shortcut)
    }

    func resetAll() {
        custom = [:]
        save()
    }

    private func assign(_ keys: ShortcutKeys, to shortcut: RemoteShortcut) {
        custom[shortcut.rawValue] = keys == shortcut.defaultKeys ? nil : keys
    }

    private func save() {
        if custom.isEmpty {
            UserDefaults.standard.removeObject(forKey: Self.storageKey)
        } else if let data = try? JSONEncoder().encode(custom) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

extension ShortcutKeys {
    /// ⌃ ⌥ ⇧ ⌘ only – ignores caps lock, fn and the numeric-pad flag arrows carry.
    static let relevantModifiers: NSEvent.ModifierFlags = [.control, .option, .shift, .command]

    init(event: NSEvent) {
        self.init(
            modifiers: event.modifierFlags.intersection(Self.relevantModifiers).rawValue,
            keyCode: event.keyCode
        )
    }

    var modifierFlags: NSEvent.ModifierFlags { NSEvent.ModifierFlags(rawValue: modifiers) }

    static func caps(_ keys: ShortcutKeys) -> [String] {
        let flags = keys.modifierFlags
        var caps: [String] = []
        if flags.contains(.control) { caps.append("⌃") }
        if flags.contains(.option) { caps.append("⌥") }
        if flags.contains(.shift) { caps.append("⇧") }
        if flags.contains(.command) { caps.append("⌘") }
        caps.append(keyName(keys.keyCode))
        return caps
    }

    private static let namedKeys: [Int: String] = [
        kVK_UpArrow: "↑", kVK_DownArrow: "↓", kVK_LeftArrow: "←", kVK_RightArrow: "→",
        kVK_Return: "↩", kVK_ANSI_KeypadEnter: "⌤", kVK_Escape: "esc", kVK_Delete: "⌫",
        kVK_ForwardDelete: "⌦", kVK_Space: "space", kVK_Tab: "⇥", kVK_ANSI_Minus: "−",
        kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]

    /// Key name on a Latin layout, so ⌘K stays ⌘K while a Cyrillic layout is active.
    static func keyName(_ keyCode: UInt16) -> String {
        if let name = namedKeys[Int(keyCode)] { return name }
        let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource().takeRetainedValue()
        guard let layoutPtr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return "#\(keyCode)"
        }
        let layoutData = Unmanaged<CFData>.fromOpaque(layoutPtr).takeUnretainedValue() as Data
        let name: String? = layoutData.withUnsafeBytes { bytes in
            guard let layout = bytes.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else { return nil }
            var deadKeyState: UInt32 = 0
            var length = 0
            var chars = [UniChar](repeating: 0, count: 4)
            let status = UCKeyTranslate(
                layout, keyCode, UInt16(kUCKeyActionDown), 0, UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysMask), &deadKeyState, chars.count, &length, &chars
            )
            guard status == noErr, length > 0 else { return nil }
            return String(utf16CodeUnits: chars, count: length)
        }
        return name.map { $0.uppercased() } ?? "#\(keyCode)"
    }
}

// MARK: - Hints on the remote

/// Small key label drawn on top of a remote control.
struct ShortcutBadge: View {
    let shortcut: RemoteShortcut
    var isActive = false

    var body: some View {
        Text(shortcut.label)
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 1.5)
            .background(Capsule().fill(Color.accentColor.opacity(isActive ? 1 : 0.85)))
            .fixedSize()
            .allowsHitTesting(false)
    }
}

private struct ShortcutHintModifier: ViewModifier {
    let shortcut: RemoteShortcut
    let alignment: Alignment
    let offset: CGSize
    @AppStorage("showShortcutHints") private var showHints = false

    func body(content: Content) -> some View {
        content.overlay(alignment: alignment) {
            if showHints {
                ShortcutBadge(shortcut: shortcut).offset(offset)
            }
        }
    }
}

extension View {
    /// Shows the shortcut's key label over this control while "Show shortcut hints" is on.
    func shortcutHint(_ shortcut: RemoteShortcut, alignment: Alignment = .center, offset: CGSize = .zero) -> some View {
        modifier(ShortcutHintModifier(shortcut: shortcut, alignment: alignment, offset: offset))
    }
}
