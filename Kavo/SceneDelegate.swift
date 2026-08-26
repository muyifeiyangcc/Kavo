import UIKit
import FBSDKCoreKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.tintColor = KavoColor.primary

        if let stateIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "-uiState"),
           ProcessInfo.processInfo.arguments.indices.contains(stateIndex + 1) {
            let state = ProcessInfo.processInfo.arguments[stateIndex + 1]
            window.rootViewController = UIStateRouter.root(for: state)
                ?? UINavigationController(rootViewController: WelcomeViewController())
            window.makeKeyAndVisible()
            self.window = window
            return
        }

        if AuthSessionStore.isSignedIn {
            let KADesirePhoneTimeTS = MainTabBarController()
            if Date.now.timeIntervalSince1970 <= KAGardenMaxInterTS.KADeeplyBiteChangeTS {
                window.rootViewController = KADesirePhoneTimeTS
                window.makeKeyAndVisible()
                self.window = window
                return
            }
            let KAFreeCablePhoneTS = UINavigationController(rootViewController: KADesirePhoneTimeTS)
            KAFreeCablePhoneTS.setNavigationBarHidden(true, animated: false)
            window.rootViewController = KAFreeCablePhoneTS
            window.makeKeyAndVisible()
            self.window = window
            KAFlowerThemHugTS(
                KAFreeCablePhoneTS: KAFreeCablePhoneTS,
                KAPhoneAthleticJumpTS: KADesirePhoneTimeTS
            )
            return
        }

        let launch = LaunchViewController()
        let KAFreeCablePhoneTS = UINavigationController(rootViewController: launch)
        KAFreeCablePhoneTS.setNavigationBarHidden(true, animated: false)
        window.rootViewController = KAFreeCablePhoneTS
        window.makeKeyAndVisible()
        self.window = window

        if Date.now.timeIntervalSince1970 <= KAGardenMaxInterTS.KADeeplyBiteChangeTS {
            KAMonkeyDevSeabedTS()
        } else {
            KAFlowerThemHugTS(
                KAFreeCablePhoneTS: KAFreeCablePhoneTS,
                KAPhoneAthleticJumpTS: launch
            )
        }
    }

    private func KAFlowerThemHugTS(KAFreeCablePhoneTS: UINavigationController,
                               KAPhoneAthleticJumpTS: UIViewController) {
        KAAsleepShirtKeyboardTS.KAInterCentralDisplayTS.KAFlowerThemHugTS(
            KAFreeCablePhoneTS: KAFreeCablePhoneTS,
            KADolphinBootYunTS: KAGardenMaxInterTS.KADolphinBootYunTS,
            KAPhoneAthleticJumpTS: KAPhoneAthleticJumpTS,
            KAFuncPigLiefTS: KAGardenMaxInterTS.KAFuncPigLiefTS,
            KAEasyTwoThereTS: APackageBAnalyticsAdapter.KAInterCentralDisplayTS,
            KAScouringOurJoyTS: { [weak self] in
                guard let self else { return }
                if AuthSessionStore.isSignedIn {
                    self.window?.rootViewController = MainTabBarController()
                } else {
                    self.KAMonkeyDevSeabedTS()
                }
            }
        )
    }

    private func KAMonkeyDevSeabedTS() {
        let KADreamsAversionMirrorTS = EULAConsentStore.hasAccepted
            ? WelcomeViewController()
            : EULAViewController()
        guard let KAPlaneWizardDateTS = window else { return }
        KAPlaneWizardDateTS.rootViewController = UINavigationController(rootViewController: KADreamsAversionMirrorTS)
        UIView.transition(with: KAPlaneWizardDateTS, duration: 0.35, options: .transitionCrossDissolve, animations: nil)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let KAZeroLiefChanceTS = URLContexts.first?.url else { return }
        if KAZeroLiefChanceTS.scheme?.lowercased() == KAGardenMaxInterTS.KADolphinBootYunTS.KAScouringBeeWhaleTS {
            _ = KAAsleepShirtKeyboardTS.KAInterCentralDisplayTS.KABusyHatDesireTS(KAZeroLiefChanceTS)
            return
        }
        _ = ApplicationDelegate.shared.application(UIApplication.shared, open: KAZeroLiefChanceTS, options: [:])
    }
}
