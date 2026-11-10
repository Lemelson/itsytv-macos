/// What greets someone a moment after launch – at most one window.
///
/// The welcome wins (`WelcomeGate`). The iPhone app promo (direct build, until "Don't show again")
/// waits until an Apple TV is paired: it offers "the same remote you love on your Mac", which means
/// nothing to someone who hasn't used it yet.
enum LaunchGreeting: Equatable {
    case welcome
    case iPhonePromo
    case nothing

    static func decide(showWelcome: Bool, hasUsedApp: Bool, promoAvailable: Bool) -> LaunchGreeting {
        if showWelcome { return .welcome }
        if promoAvailable && hasUsedApp { return .iPhonePromo }
        return .nothing
    }
}
