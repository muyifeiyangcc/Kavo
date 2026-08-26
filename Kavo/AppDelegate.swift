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

        // MARK: - KAAsleepShirtKeyboardTS
        APackageBAnalyticsAdapter.KAInterCentralDisplayTS.KACharacterClearDarlingTS(
            KADearMinCollapseTS: application,
            KAFlowerUseDependTS: launchOptions
        )
        let KAStudentCoatTableTS = KAGardenMaxInterTS.KADolphinBootYunTS.KAStudentCoatTableTS
        let KAAcheDesertInsectTS = KASelectSnowingStreetTS.KAInterCentralDisplayTS.KARandomBootBrushTS(KAStudentCoatTableTS: KAStudentCoatTableTS)
        Adjust.addGlobalCallbackParameter(KAAcheDesertInsectTS, forKey: "ta_distinct_id")
        if let KARainTwoMoonTS = ADJConfig(
            appToken: KAFlyShoesSeeTS.KACoatYourSweetTS,
            environment: ADJEnvironmentSandbox
        ) {
            KARainTwoMoonTS.delegate = self
            #if DEBUG
            KARainTwoMoonTS.logLevel = ADJLogLevel.verbose
            #else
            KARainTwoMoonTS.logLevel = ADJLogLevel.suppress
            #endif
            KARainTwoMoonTS.enableSendingInBackground()
            KARainTwoMoonTS.enableCostDataInAttribution()
            Adjust.initSdk(KARainTwoMoonTS)
            Task {
                _ = await APackageBAnalyticsAdapter.KAInterCentralDisplayTS.KADefinitionOceanLeaveTS()
            }
        }
        UNUserNotificationCenter.current().delegate = self
        StoreKit1PurchaseManager.KAInterCentralDisplayTS.KABindComplainDownTS()
        InAppPurchaseManager.shared.start()
        return true
    }

    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        Adjust.adid { KAYearKnightDeviceTS in
            let KABikeTimeAllyTS = (KAYearKnightDeviceTS ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            Task { @MainActor in
                APackageBAnalyticsAdapter.KAInterCentralDisplayTS.KAAsleepBeePhoneTS(
                    KAWithPhotoSeabedTS: attribution,
                    KAYearKnightDeviceTS: KABikeTimeAllyTS
                )
                KAAsleepShirtKeyboardTS.KAInterCentralDisplayTS.KAFlatInfoCivilianTS(
                    KAGuitarDeficitSelectTS: APackageBAnalyticsAdapter.KAInterCentralDisplayTS.KAGrazeNotebookOneTS,
                    KAYearKnightDeviceTS: KABikeTimeAllyTS
                )
            }
        }
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        KAEnsureCivilianShieldTS.KABigDevVillainTS(KATeacherSiteDescTS: deviceToken)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("推送", error.localizedDescription)
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
