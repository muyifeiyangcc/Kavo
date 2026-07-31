import UIKit

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
            window.rootViewController = MainTabBarController()
            window.makeKeyAndVisible()
            self.window = window
            return
        }
        let launch = LaunchViewController()
        launch.onFinished = { [weak window] in
            let root = EULAConsentStore.hasAccepted
                ? WelcomeViewController()
                : EULAViewController()
            window?.rootViewController = UINavigationController(rootViewController: root)
            UIView.transition(with: window!, duration: 0.35, options: .transitionCrossDissolve, animations: nil)
        }
        window.rootViewController = launch
        window.makeKeyAndVisible()
        self.window = window
    }
}
