#if canImport(AdjustSdk)
import AdjustSdk
#endif
import FBSDKCoreKit
import Foundation
import UIKit

final class APackageBAnalyticsAdapter: KAEraserOctopusDeeplyTS {
    static let KAInterCentralDisplayTS = APackageBAnalyticsAdapter()

    private let KAVillainOilDownTS = NSLock()
    private var KADependLagBombTS = KASelectSnowingStreetTS.KAInterCentralDisplayTS.KATracksMayAntiTS
    private var KAWoodGuitarZooTS = ""
    private var KAWinChairBoatTS = false

    private init() {}

    var KATracksMayAntiTS: String {
        KAVillainOilDownTS.lock()
        defer { KAVillainOilDownTS.unlock() }
        return KADependLagBombTS
    }

    var KAGrazeNotebookOneTS: String {
        KAVillainOilDownTS.lock()
        defer { KAVillainOilDownTS.unlock() }
        return KAWoodGuitarZooTS
    }

    func KADefinitionOceanLeaveTS() async -> String {
        let KALiefPaintDespiteTS = KATracksMayAntiTS
        if !KALiefPaintDespiteTS.isEmpty {
            return KALiefPaintDespiteTS
        }

        #if canImport(AdjustSdk)
        for KAHoorayAskGoldTS in 1...3 {
            let KAArsenalTameBorderTS: String = await withCheckedContinuation { KALaterBlowTrialsTS in
                Adjust.adid { KAYearKnightDeviceTS in
                    KALaterBlowTrialsTS.resume(
                        returning: (KAYearKnightDeviceTS ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                }
            }
            if !KAArsenalTameBorderTS.isEmpty {
                KADiscussionBeeThemTS(KAArsenalTameBorderTS)
                KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS(
                    "Adjust",
                    "主动获取 adid 成功（第 \(KAHoorayAskGoldTS) 次）"
                )
                return KAArsenalTameBorderTS
            }
            if KAHoorayAskGoldTS < 3 {
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        #endif

        let KAMyEraserOffTS = KATracksMayAntiTS
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS(
            "Adjust",
            "主动获取 adid 失败，登录接口不会上传空值"
        )
        return KAMyEraserOffTS
    }

    func KAAsleepBeePhoneTS(KAWithPhotoSeabedTS: ADJAttribution?, KAYearKnightDeviceTS: String) {
        let KAGuitarDeficitSelectTS = KARedLastCentralTS(KAWithPhotoSeabedTS)
        KADiscussionBeeThemTS(KAYearKnightDeviceTS)
        KAVillainOilDownTS.lock()
        KAWoodGuitarZooTS = KAGuitarDeficitSelectTS
        KAVillainOilDownTS.unlock()

        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS(
            "Adjust",
            "收到归因回调，adid=\(KAYearKnightDeviceTS.isEmpty ? "空" : "非空")，ajResult=\(KAGuitarDeficitSelectTS.isEmpty ? "空字符串" : "非空")"
        )
    }

    private func KADiscussionBeeThemTS(_ KAYearKnightDeviceTS: String) {
        let KABikeTimeAllyTS = KAYearKnightDeviceTS.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !KABikeTimeAllyTS.isEmpty else { return }
        KAVillainOilDownTS.lock()
        KADependLagBombTS = KABikeTimeAllyTS
        KAVillainOilDownTS.unlock()
        KASelectSnowingStreetTS.KAInterCentralDisplayTS.KATracksMayAntiTS = KABikeTimeAllyTS
    }

    func KARedLastCentralTS(_ KAWithPhotoSeabedTS: ADJAttribution?) -> String {
        guard let KAWithPhotoSeabedTS else { return "" }
        let KAInterCivilianBusTS: [String: Any] = [
            "trackerToken": KAWithPhotoSeabedTS.trackerToken ?? "",
            "trackerName": KAWithPhotoSeabedTS.trackerName ?? "",
            "network": KAWithPhotoSeabedTS.network ?? "",
            "campaign": KAWithPhotoSeabedTS.campaign ?? "",
            "adgroup": KAWithPhotoSeabedTS.adgroup ?? "",
            "creative": KAWithPhotoSeabedTS.creative ?? "",
            "clickLabel": KAWithPhotoSeabedTS.clickLabel ?? "",
            "costType": KAWithPhotoSeabedTS.costType ?? "",
            "costAmount": KAWithPhotoSeabedTS.costAmount ?? 0,
            "costCurrency": KAWithPhotoSeabedTS.costCurrency ?? ""
        ]
        guard JSONSerialization.isValidJSONObject(KAInterCivilianBusTS),
              let KADesertCountPaintTS = try? JSONSerialization.data(withJSONObject: KAInterCivilianBusTS, options: [.sortedKeys]) else {
            return ""
        }
        return String(decoding: KADesertCountPaintTS, as: UTF8.self)
    }

    func KARandomMusicChangeTS(_ KAUntilCenterCountTS: KAXrcSoleToolTS,
                                  KABeeEarthSayTS: Decimal?,
                                  KAListAnySauceTS: String?) {
        let KABorderPrivacyBirthTS: String
        let KAHighShirtDorsalTS: String
        switch KAUntilCenterCountTS {
        case .KASeabedWindQuizzesTS:
            KABorderPrivacyBirthTS = KAFlyShoesSeeTS.KANorDisVocabularyTS
            KAHighShirtDorsalTS = KAFlyShoesSeeTS.KAMonkeySwordGrapeTS
        case .KACarDrpWaterTS:
            KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS(
                "Adjust",
                "InitiateCheckout 按最新规则不发送 Adjust SDK，只调用后端 ...j"
            )
            return
        case .KAScreenSlimeNetTS:
            KABorderPrivacyBirthTS = KAFlyShoesSeeTS.KAPrivacyTreejoinTS
            KAHighShirtDorsalTS = KAFlyShoesSeeTS.KASwordCeillingFuncTS
        }

        guard let KASnowBirdShipTS = ADJEvent(eventToken: KABorderPrivacyBirthTS) else {
            KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("Adjust", "无法创建 \(KAHighShirtDorsalTS) 事件")
            return
        }
        if KAUntilCenterCountTS == .KAScreenSlimeNetTS {
            guard let KABeeEarthSayTS,
                  let KAListAnySauceTS,
                  !KAListAnySauceTS.isEmpty else {
                KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("Adjust", "Purchase 缺少 StoreKit 实际金额或币种，已拒绝发送")
                return
            }
            KASnowBirdShipTS.setRevenue(
                NSDecimalNumber(decimal: KABeeEarthSayTS).doubleValue,
                currency: KAListAnySauceTS
            )
        }
        Adjust.trackEvent(KASnowBirdShipTS)
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("Adjust", "已发送 SDK 事件 \(KAHighShirtDorsalTS)")
    }

    @MainActor
    func KACharacterClearDarlingTS(
        KADearMinCollapseTS: UIApplication,
        KAFlowerUseDependTS: [UIApplication.LaunchOptionsKey: Any]?
    ) {
        guard !KAWinChairBoatTS else { return }
        let KAComesWaterMirrorTS = KASelectSnowingStreetTS.KAInterCentralDisplayTS
        if KAComesWaterMirrorTS.KASeeResTeacherTS.isEmpty {
            KAComesWaterMirrorTS.KASeeResTeacherTS = KAFlyShoesSeeTS.KASeeResTeacherTS
        }
        if KAComesWaterMirrorTS.KAOrNorPaintTS.isEmpty {
            KAComesWaterMirrorTS.KAOrNorPaintTS = KAFlyShoesSeeTS.KAOrNorPaintTS
        }
        if KAComesWaterMirrorTS.KABessTestMakeTS.isEmpty {
            KAComesWaterMirrorTS.KABessTestMakeTS = KAFlyShoesSeeTS.KABessTestMakeTS
        }

        let KASeedBiologicalNodeTS = Settings.shared
        KASeedBiologicalNodeTS.appID = KAComesWaterMirrorTS.KASeeResTeacherTS
        KASeedBiologicalNodeTS.clientToken = KAComesWaterMirrorTS.KAOrNorPaintTS
        KASeedBiologicalNodeTS.displayName = KAComesWaterMirrorTS.KABessTestMakeTS
        KASeedBiologicalNodeTS.isAutoLogAppEventsEnabled = true
        ApplicationDelegate.shared.application(
            KADearMinCollapseTS,
            didFinishLaunchingWithOptions: KAFlowerUseDependTS
        )
        KAWinChairBoatTS = true
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS(
            "Facebook",
            "已使用持久化配置初始化 SDK"
        )
    }

    func KAWindWinCoffeeTS(KABeeEarthSayTS: Decimal, KAListAnySauceTS: String) {
        guard KAWinChairBoatTS else {
            KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("Facebook", "SDK 尚未初始化，Purchase 未发送")
            return
        }
        AppEvents.shared.logPurchase(
            amount: NSDecimalNumber(decimal: KABeeEarthSayTS).doubleValue,
            currency: KAListAnySauceTS,
            parameters: [AppEvents.ParameterName("fb_mobile_purchase"): "true"]
        )
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS(
            "Facebook",
            "已发送 Purchase，金额=\(KABeeEarthSayTS)，币种=\(KAListAnySauceTS)"
        )
    }
}
