import SwiftUI
import ItsytvCore

/// Every keyboard shortcut of the remote panel. The panel's key handler, the
/// on-remote hints and the Keyboard Shortcuts window all read this one table.
enum RemoteShortcut: String, CaseIterable, Identifiable {
    case up, down, left, right, select, back, home
    case playPause, volumeUp, volumeDown, mute
    case keyboard, appSearch, close

    var id: String { rawValue }

    /// Key caps as drawn on screen, one string per cap.
    var keyCaps: [String] {
        switch self {
        case .up: ["↑"]
        case .down: ["↓"]
        case .left: ["←"]
        case .right: ["→"]
        case .select: ["↩"]
        case .back: ["esc"]
        case .home: ["⌫"]
        case .playPause: ["space"]
        case .volumeUp: ["="]
        case .volumeDown: ["−"]
        case .mute: ["⌘", "⇧", "M"]
        case .keyboard: ["⌘", "K"]
        case .appSearch: ["⌘", "F"]
        case .close: ["⌘", "W"]
        }
    }

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
    var usesCommand: Bool { keyCaps.first == "⌘" }

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
        let flags = event.modifierFlags
        if flags.contains(.command) {
            switch event.keyCode {
            case 13, 4: return .close // ⌘W, ⌘H
            case 40: return .keyboard
            case 3: return .appSearch
            default: break
            }
        }
        if flags.contains([.command, .shift]), event.keyCode == 46 {
            return .mute
        }
        switch event.keyCode {
        case 126: return .up
        case 125: return .down
        case 123: return .left
        case 124: return .right
        case 36: return .select
        case 51: return .home
        case 53: return .back
        case 49: return .playPause
        case 24: return .volumeUp
        case 27: return .volumeDown
        default: return nil
        }
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
