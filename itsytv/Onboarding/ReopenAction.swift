/// What opening Itsytv again – from Spotlight, Finder or the Dock while it's running – shows.
///
/// Someone who can't see the menu bar icon still gets the app: the remote if a paired Apple TV is
/// around, otherwise the device menu, where pairing starts.
enum ReopenAction: Equatable {
    case focusRemote
    case openRemote(deviceID: String)
    case showDevices

    static func decide(remoteIsOpen: Bool, lastPairedDeviceNearby: String?) -> ReopenAction {
        if remoteIsOpen { return .focusRemote }
        if let lastPairedDeviceNearby { return .openRemote(deviceID: lastPairedDeviceNearby) }
        return .showDevices
    }
}
