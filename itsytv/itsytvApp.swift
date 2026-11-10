import SwiftUI
import AppIntents
import ItsytvCore

@main
struct itsytvApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(appDelegate.manager)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) weak var shared: AppDelegate?

    let manager = AppleTVManager()
    let iconLoader = AppIconLoader()
    var appController: AppController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG
        ItsytvCoreLog.verbose = true
        #endif
        Self.shared = self
        if DockIcon.isOn { DockIcon.apply() }
        appController = AppController(manager: manager, iconLoader: iconLoader)
        ItsyTVShortcuts.updateAppShortcutParameters()
        // Give the menu bar a moment to place the icon before checking whether it can be seen.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.greet()
        }
    }

    /// The welcome or (direct build) the iPhone app promo, as `LaunchGreeting` decides.
    private func greet() {
        guard let appController else { return }
        let hasUsedApp = manager.lastConnectedDeviceID != nil
        let showWelcome = WelcomeGate(defaults: .standard).shouldShow(
            hasUsedApp: hasUsedApp, iconHidden: appController.isIconHidden, inDock: DockIcon.isOn)
        #if APPSTORE
        let promoAvailable = false
        #else
        let promoAvailable = IosPromoHelper.shouldShow
        #endif
        switch LaunchGreeting.decide(showWelcome: showWelcome, hasUsedApp: hasUsedApp, promoAvailable: promoAvailable) {
        case .welcome:
            WelcomeWindow.show(iconHidden: { appController.isIconHidden }, showDevices: appController.showDevices)
        case .iPhonePromo:
            #if !APPSTORE
            IosPromoHelper.showIfNeeded()
            #endif
        case .nothing:
            break
        }
    }

    /// Opening Itsytv again while it runs shows the remote or the device menu (`AppController.handleReopen`).
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        appController?.handleReopen()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        appController?.cleanup()
    }
}
