import UIKit
import IQKeyboardManagerSwift
import IQKeyboardToolbarManager
import UserNotifications
import FBSDKCoreKit
import AdjustSdk

@main
final class AppDelegate: UIResponder, UIApplicationDelegate, AdjustDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardToolbarManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true

        // MARK: - BPackage
        APackageBAnalyticsAdapter.bPackageShared.bPackageInitializeFacebook(
            bPackageApplication: application,
            bPackageLaunchOptions: launchOptions
        )
        let bPackageAppID = BPackageProfile.bPackageConfiguration.bPackageAppID
        let bPackageDeviceID = BPackageStorage.bPackageShared.bPackageStableDeviceID(bPackageAppID: bPackageAppID)
        Adjust.addGlobalCallbackParameter(bPackageDeviceID, forKey: "ta_distinct_id")
        if let bPackageAdjustConfig = ADJConfig(
            appToken: BPackageThirdPartyProfile.bPackageAdjustAppToken,
            environment: ADJEnvironmentSandbox
        ) {
            bPackageAdjustConfig.delegate = self
            #if DEBUG
            bPackageAdjustConfig.logLevel = ADJLogLevel.verbose
            #else
            bPackageAdjustConfig.logLevel = ADJLogLevel.suppress
            #endif
            bPackageAdjustConfig.enableSendingInBackground()
            bPackageAdjustConfig.enableCostDataInAttribution()
            Adjust.initSdk(bPackageAdjustConfig)
            Task {
                _ = await APackageBAnalyticsAdapter.bPackageShared.bPackageResolveAdjustAdID()
            }
        }
        UNUserNotificationCenter.current().delegate = self
        StoreKit1PurchaseManager.bPackageShared.bPackageStartObserving()
        InAppPurchaseManager.shared.start()
        return true
    }

    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        Adjust.adid { bPackageAdID in
            let bPackageNormalizedAdID = (bPackageAdID ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            Task { @MainActor in
                APackageBAnalyticsAdapter.bPackageShared.bPackageUpdateAttribution(
                    bPackageAttribution: attribution,
                    bPackageAdID: bPackageNormalizedAdID
                )
                BPackage.bPackageShared.bPackageAdjustAttributionChanged(
                    bPackageResult: APackageBAnalyticsAdapter.bPackageShared.bPackageAttributionResult,
                    bPackageAdID: bPackageNormalizedAdID
                )
            }
        }
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        BPackageAppDelegateSupport.bPackageDidRegisterForRemoteNotifications(bPackageDeviceToken: deviceToken)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        BPackageLogger.bPackageShared.bPackageLog("推送", error.localizedDescription)
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options connectionOptions: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
