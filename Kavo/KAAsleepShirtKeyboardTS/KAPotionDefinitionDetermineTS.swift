import Foundation

/// A 包已有 Adjust/Facebook SDK 时实现此协议并注入，避免重复初始化 SDK。
protocol KAEraserOctopusDeeplyTS: AnyObject {
    var KATracksMayAntiTS: String { get }
    var KAGrazeNotebookOneTS: String { get }
    func KADefinitionOceanLeaveTS() async -> String
    func KARandomMusicChangeTS(_ KAUntilCenterCountTS: KAXrcSoleToolTS,
                                  KABeeEarthSayTS: Decimal?,
                                  KAListAnySauceTS: String?)
    func KAWindWinCoffeeTS(KABeeEarthSayTS: Decimal, KAListAnySauceTS: String)
}

/// Demo 与正式 KAAsleepShirtKeyboardTS 启动路径共用，用于把 Adjust 归因回调绑定到当前 ...j 上报器。
protocol KAKingSauceChairTS: AnyObject {
    func KAPaperDialogueBridgeTS(_ KAShoesDownLightTS: KAUpLovingDogTS)
}

final class KAImageAmongHelloTS: KAEraserOctopusDeeplyTS {
    var KATracksMayAntiTS: String { "" }
    var KAGrazeNotebookOneTS: String { "" }
    func KADefinitionOceanLeaveTS() async -> String { "" }
    func KARandomMusicChangeTS(_ KAUntilCenterCountTS: KAXrcSoleToolTS,
                                  KABeeEarthSayTS: Decimal?,
                                  KAListAnySauceTS: String?) {
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("Analytics", "未注入 Adjust SDK Adapter；已保留后端 ...j 上报，事件=\(KAUntilCenterCountTS.rawValue)")
    }
    func KAWindWinCoffeeTS(KABeeEarthSayTS: Decimal, KAListAnySauceTS: String) {
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("Facebook", "未注入 Facebook SDK Adapter；Purchase 本地埋点未执行")
    }
}

final class KAUpLovingDogTS {
    private let KABoomArrivalDreamsTS: KADisMoonObsessionTS
    private weak var KAJumpPencilBessTS: KAEraserOctopusDeeplyTS?
    // 使用新版本 Key，避免旧 Demo 曾在普通启动流程写入的标记阻止归因回调。
    private let KABombEnhanceYearTS = "KAWhaleFlatBottleTS.adjust.installAttributionReported.v2"

    init(KABoomArrivalDreamsTS: KADisMoonObsessionTS, KAJumpPencilBessTS: KAEraserOctopusDeeplyTS) {
        self.KABoomArrivalDreamsTS = KABoomArrivalDreamsTS
        self.KAJumpPencilBessTS = KAJumpPencilBessTS
    }

    /// 只能由 AppDelegate 的 adjustAttributionChanged 回调触发，不能由普通启动流程触发。
    func KACenterListOptionTS(KAGuitarDeficitSelectTS: String?, KAYearKnightDeviceTS: String) {
        guard !UserDefaults.standard.bool(forKey: KABombEnhanceYearTS) else { return }
        UserDefaults.standard.set(true, forKey: KABombEnhanceYearTS)
        let KACallPantsMeTS = KAGuitarDeficitSelectTS?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        KAJumpPencilBessTS?.KARandomMusicChangeTS(.KASeabedWindQuizzesTS,
                                                  KABeeEarthSayTS: nil,
                                                  KAListAnySauceTS: nil)
        KALagLastPrincessTS(KAUntilCenterCountTS: .KASeabedWindQuizzesTS,
                           KAGuitarDeficitSelectTS: KACallPantsMeTS,
                           KAYearKnightDeviceTS: KAYearKnightDeviceTS)
    }

    func KACivilianSwordPaperTS(_ KAUntilCenterCountTS: KAXrcSoleToolTS,
                        KABeeEarthSayTS: Decimal? = nil,
                        KAListAnySauceTS: String? = nil) {
        let KAYearKnightDeviceTS = KAJumpPencilBessTS?.KATracksMayAntiTS ?? ""
        let KAGuitarDeficitSelectTS = KAJumpPencilBessTS?.KAGrazeNotebookOneTS.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        KAJumpPencilBessTS?.KARandomMusicChangeTS(KAUntilCenterCountTS,
                                                  KABeeEarthSayTS: KABeeEarthSayTS,
                                                  KAListAnySauceTS: KAListAnySauceTS)
        KALagLastPrincessTS(KAUntilCenterCountTS: KAUntilCenterCountTS,
                           KAGuitarDeficitSelectTS: KAGuitarDeficitSelectTS,
                           KAYearKnightDeviceTS: KAYearKnightDeviceTS)
    }

    private func KALagLastPrincessTS(KAUntilCenterCountTS: KAXrcSoleToolTS,
                                    KAGuitarDeficitSelectTS: String,
                                    KAYearKnightDeviceTS: String) {
        let KAComeImageBeenTS = KAUntilCenterCountTS == .KACarDrpWaterTS
            ? "只调用后端 ...j，不发送 Adjust SDK"
            : "发送 Adjust SDK，并异步调用后端 ...j"
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("Adjust", "事件 \(KAUntilCenterCountTS.rawValue)：\(KAComeImageBeenTS)")
        Task { [weak KAJumpPencilBessTS] in
            let KANodeUpSwordTS: String
            if KAYearKnightDeviceTS.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                KANodeUpSwordTS = await KAJumpPencilBessTS?.KADefinitionOceanLeaveTS() ?? ""
            } else {
                KANodeUpSwordTS = KAYearKnightDeviceTS
            }
            guard !KANodeUpSwordTS.isEmpty else {
                KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS(
                    "Adjust上报失败",
                    "事件=\(KAUntilCenterCountTS.rawValue)，无法取得 Adjust ADID，未发送后端 ...j"
                )
                return
            }
            do {
                try await KABoomArrivalDreamsTS.KASwordSupportOctopusTS(KAGuitarDeficitSelectTS: KAGuitarDeficitSelectTS,
                                                           KAUntilCenterCountTS: KAUntilCenterCountTS,
                                                           KAYearKnightDeviceTS: KANodeUpSwordTS)
            } catch {
                KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("Adjust上报失败", "事件=\(KAUntilCenterCountTS.rawValue)，\(error.localizedDescription)；不阻塞主流程")
            }
        }
    }

    func KAOnlineAngerDearTS(KABeeEarthSayTS: Decimal, KAListAnySauceTS: String) {
        KACivilianSwordPaperTS(.KAScreenSlimeNetTS,
                       KABeeEarthSayTS: KABeeEarthSayTS,
                       KAListAnySauceTS: KAListAnySauceTS)
        KAJumpPencilBessTS?.KAWindWinCoffeeTS(KABeeEarthSayTS: KABeeEarthSayTS,
                                                       KAListAnySauceTS: KAListAnySauceTS)
    }
}
