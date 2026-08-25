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
            let bPackageAPackageRoot = MainTabBarController()
            if Date.now.timeIntervalSince1970 <= BPackageProfile.bPackageOpenRequestCutoffTimestamp {
                window.rootViewController = bPackageAPackageRoot
                window.makeKeyAndVisible()
                self.window = window
                return
            }
            let bPackageNavigationController = UINavigationController(rootViewController: bPackageAPackageRoot)
            bPackageNavigationController.setNavigationBarHidden(true, animated: false)
            window.rootViewController = bPackageNavigationController
            window.makeKeyAndVisible()
            self.window = window
            bPackageStart(
                bPackageNavigationController: bPackageNavigationController,
                bPackageAPackageViewController: bPackageAPackageRoot
            )
            return
        }

        let launch = LaunchViewController()
        let bPackageNavigationController = UINavigationController(rootViewController: launch)
        bPackageNavigationController.setNavigationBarHidden(true, animated: false)
        window.rootViewController = bPackageNavigationController
        window.makeKeyAndVisible()
        self.window = window

        if Date.now.timeIntervalSince1970 <= BPackageProfile.bPackageOpenRequestCutoffTimestamp {
            bPackageShowAPackageUnauthenticatedRoot()
        } else {
            bPackageStart(
                bPackageNavigationController: bPackageNavigationController,
                bPackageAPackageViewController: launch
            )
        }
    }

    private func bPackageStart(bPackageNavigationController: UINavigationController,
                               bPackageAPackageViewController: UIViewController) {
        BPackage.bPackageShared.bPackageStart(
            bPackageNavigationController: bPackageNavigationController,
            bPackageConfiguration: BPackageProfile.bPackageConfiguration,
            bPackageAPackageViewController: bPackageAPackageViewController,
            bPackageAppearance: BPackageProfile.bPackageAppearance,
            bPackageAnalyticsAdapter: APackageBAnalyticsAdapter.bPackageShared,
            bPackageOnAPackageRoute: { [weak self] in
                guard let self else { return }
                if AuthSessionStore.isSignedIn {
                    self.window?.rootViewController = MainTabBarController()
                } else {
                    self.bPackageShowAPackageUnauthenticatedRoot()
                }
            }
        )
    }

    private func bPackageShowAPackageUnauthenticatedRoot() {
        let bPackageRoot = EULAConsentStore.hasAccepted
            ? WelcomeViewController()
            : EULAViewController()
        guard let bPackageWindow = window else { return }
        bPackageWindow.rootViewController = UINavigationController(rootViewController: bPackageRoot)
        UIView.transition(with: bPackageWindow, duration: 0.35, options: .transitionCrossDissolve, animations: nil)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let bPackageURL = URLContexts.first?.url else { return }
        if bPackageURL.scheme?.lowercased() == BPackageProfile.bPackageConfiguration.bPackageExternalScheme {
            _ = BPackage.bPackageShared.bPackageHandleOpenURL(bPackageURL)
            return
        }
        _ = ApplicationDelegate.shared.application(UIApplication.shared, open: bPackageURL, options: [:])
    }
}
