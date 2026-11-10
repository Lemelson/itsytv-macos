import CoreGraphics

/// Whether people can see the menu bar icon.
///
/// macOS keeps `NSStatusItem.isVisible` true for an icon it hides – pushed behind the notch when the
/// menu bar is full, or turned off in System Settings → Menu Bar – so the icon's own window is
/// checked instead: it loses `.visible` from its occlusion state, or sits in the notch gap or off
/// its screen (as Tailscale and Snapzy measured, 2026). It can't tell the two causes apart.
enum MenuBarIconVisibility {
    static func isHidden(windowVisible: Bool, iconFrame: CGRect?, screenFrame: CGRect?, notchGap: CGRect?) -> Bool {
        guard windowVisible, let iconFrame, let screenFrame else { return true }
        guard iconFrame.minX >= screenFrame.minX, iconFrame.maxX <= screenFrame.maxX else { return true }
        if let notchGap, iconFrame.intersects(notchGap) { return true }
        return false
    }

    /// The notch's span in the menu bar, from the usable areas either side of it
    /// (`NSScreen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea`; both nil without a notch).
    static func notchGap(left: CGRect?, right: CGRect?) -> CGRect? {
        guard let left, let right, right.minX > left.maxX else { return nil }
        return CGRect(x: left.maxX, y: min(left.minY, right.minY),
                      width: right.minX - left.maxX, height: max(left.height, right.height))
    }

    /// Where the remote or the device menu goes when the icon is hidden: centred at the top of the
    /// screen, just under the menu bar. Returns the top-left corner.
    static func fallbackTopLeft(visibleFrame: CGRect, width: CGFloat) -> CGPoint {
        CGPoint(x: visibleFrame.midX - width / 2, y: visibleFrame.maxY)
    }
}
