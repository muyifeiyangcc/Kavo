import Foundation
import StoreKit

final class StoreKit1PurchaseManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate {
    static let KAInterCentralDisplayTS = StoreKit1PurchaseManager()

    enum KABinMomentsFuncTS {
        case KAArrestBigBinTS(String)
        case KALabelDegreeWoodTS(String)
        case KACallLineHatTS(String)
        case KASeeLaptopPerfectTS
    }

    private struct KAOnlinePlaneTipTS: Codable {
        let KAShirtDreamsSixTS: String
        let KAGoodNetCoffeeTS: String
        var KABeeEarthSayTS: String?
        var KAListAnySauceTS: String?
    }

    private var KACharacterThereEveryTS: ((KABinMomentsFuncTS) -> Void)?
    private var KABoomArrivalDreamsTS: KADisMoonObsessionTS?
    private var KAFuncVcGoldTS: KAUpLovingDogTS?
    private var KAComplainCryArsenalTS: SKProductsRequest?
    private var KAMaxKnowWantTS: SKReceiptRefreshRequest?
    private var KAAcheMusicDragonTS: [SKPaymentTransaction] = []
    private var KAElephantPrincePaintTS = Set<String>()
    private let KAPantsDialogueBigTS = "KAWhaleFlatBottleTS.storeKit1.pendingPaymentContext"
    private let KAZeroTracksGoldTS = "KAWhaleFlatBottleTS.storeKit1.ownedProductIDs"
    private let KAPhoneClearDelTS = "KAWhaleFlatBottleTS.storeKit1.verifiedTransactionIDs"

    private override init() { super.init() }

    func KABindComplainDownTS() {
        SKPaymentQueue.default().add(self)
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("StoreKit1", "交易观察者已在 App 启动时注册")
    }

    func KASupportColorsShadowTS() { SKPaymentQueue.default().remove(self) }

    func KASnowShieldTableTS(KABoomArrivalDreamsTS: KADisMoonObsessionTS,
                           KAFuncVcGoldTS: KAUpLovingDogTS,
                           KACharacterThereEveryTS: @escaping (KABinMomentsFuncTS) -> Void) {
        self.KABoomArrivalDreamsTS = KABoomArrivalDreamsTS
        self.KAFuncVcGoldTS = KAFuncVcGoldTS
        self.KACharacterThereEveryTS = KACharacterThereEveryTS
        SKPaymentQueue.default().transactions
            .filter {
                KAThreeArsenalQuizzesTS($0.payment.productIdentifier) &&
                ($0.transactionState == .purchased || $0.transactionState == .restored)
            }
            .forEach(KABridgeImageKnightTS)
    }

    func KAAversionBirthPicTS() { KACharacterThereEveryTS = nil }

    func KAScreenSlimeNetTS(KAShirtDreamsSixTS: String, KAGoodNetCoffeeTS: String) {
        guard !KAShirtDreamsSixTS.isEmpty else { KAVerSlimeScouringTS(.KACallLineHatTS("The product ID is missing.")); return }
        guard !KAGoodNetCoffeeTS.isEmpty else { KAVerSlimeScouringTS(.KACallLineHatTS("The order number is missing.")); return }
        guard SKPaymentQueue.canMakePayments() else { KAVerSlimeScouringTS(.KACallLineHatTS("In-App Purchases are not allowed on this device.")); return }
        guard SKPaymentQueue.default().transactions.allSatisfy({ $0.transactionState != .purchasing && $0.transactionState != .deferred }) else {
            KAVerSlimeScouringTS(.KACallLineHatTS("Another payment is already in progress.")); return
        }
        KADatePencilOrderTS(KAShirtDreamsSixTS)
        KADolphinDownSkyTS(KAOnlinePlaneTipTS(KAShirtDreamsSixTS: KAShirtDreamsSixTS,
                                                   KAGoodNetCoffeeTS: KAGoodNetCoffeeTS,
                                                   KABeeEarthSayTS: nil,
                                                   KAListAnySauceTS: nil))
        KAVerSlimeScouringTS(.KAArrestBigBinTS("Loading product information…"))
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("StoreKit1", "查询 KAAsleepShirtKeyboardTS 商品 Product ID=\(KAShirtDreamsSixTS)")
        let KAScouringTracksClientTS = SKProductsRequest(productIdentifiers: [KAShirtDreamsSixTS])
        KAComplainCryArsenalTS = KAScouringTracksClientTS
        KAScouringTracksClientTS.delegate = self
        KAScouringTracksClientTS.start()
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        KAComplainCryArsenalTS = nil
        guard var KACoatMorningSkyTS = KADetermineThemSnowingTS(),
              let KAJoyCoffeeWhaleTS = response.products.first(where: { $0.productIdentifier == KACoatMorningSkyTS.KAShirtDreamsSixTS }) else {
            let KATimeBlindOppTS = response.invalidProductIdentifiers.joined(separator: ",")
            KACloudLineBusyTS()
            KAVerSlimeScouringTS(.KACallLineHatTS("The App Store product was not found. Invalid product ID: \(KATimeBlindOppTS)"))
            return
        }
        guard let KAListAnySauceTS = KAJoyCoffeeWhaleTS.priceLocale.currencyCode,
              !KAListAnySauceTS.isEmpty else {
            KACloudLineBusyTS()
            KAVerSlimeScouringTS(.KACallLineHatTS("The App Store did not return a valid currency."))
            return
        }
        KACoatMorningSkyTS.KABeeEarthSayTS = KAJoyCoffeeWhaleTS.price.stringValue
        KACoatMorningSkyTS.KAListAnySauceTS = KAListAnySauceTS
        KADolphinDownSkyTS(KACoatMorningSkyTS)
        let KADorsalMobileStreetTS = SKMutablePayment(product: KAJoyCoffeeWhaleTS)
        KADorsalMobileStreetTS.quantity = 1
        KAVerSlimeScouringTS(.KAArrestBigBinTS("Waiting for payment confirmation…"))
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("StoreKit1", "商品查询成功：\(KAJoyCoffeeWhaleTS.productIdentifier)，价格=\(KAJoyCoffeeWhaleTS.price)，加入支付队列")
        SKPaymentQueue.default().add(KADorsalMobileStreetTS)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        if request === KAMaxKnowWantTS {
            KAMaxKnowWantTS = nil
            KAAcheMusicDragonTS.removeAll()
            KAVerSlimeScouringTS(.KACallLineHatTS("Unable to refresh the App Store receipt: \(error.localizedDescription)"))
        } else {
            KAComplainCryArsenalTS = nil
            KACloudLineBusyTS()
            KAVerSlimeScouringTS(.KACallLineHatTS("Unable to load the App Store product: \(error.localizedDescription)"))
        }
    }

    func requestDidFinish(_ request: SKRequest) {
        guard request === KAMaxKnowWantTS else { return }
        KAMaxKnowWantTS = nil
        let KATreeVineChanceTS = KAAcheMusicDragonTS
        KAAcheMusicDragonTS.removeAll()
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("StoreKit1", "Receipt 刷新完成，继续验单")
        KATreeVineChanceTS.forEach(KABridgeImageKnightTS)
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for KATeacherConcentrateTracksTS in transactions {
            guard KAThreeArsenalQuizzesTS(KATeacherConcentrateTracksTS.payment.productIdentifier) else {
                continue
            }
            switch KATeacherConcentrateTracksTS.transactionState {
            case .purchasing:
                KAVerSlimeScouringTS(.KAArrestBigBinTS("Processing payment…"))
            case .deferred:
                KAVerSlimeScouringTS(.KAArrestBigBinTS("Payment is awaiting approval…"))
            case .purchased, .restored:
                KABridgeImageKnightTS(KATeacherConcentrateTracksTS)
            case .failed:
                let KAIndexChangeBridgeTS = KATeacherConcentrateTracksTS.error as NSError?
                queue.finishTransaction(KATeacherConcentrateTracksTS)
                KACloudLineBusyTS()
                if KAIndexChangeBridgeTS?.domain == SKErrorDomain, KAIndexChangeBridgeTS?.code == SKError.paymentCancelled.rawValue {
                    KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("StoreKit1", "用户取消支付")
                    KAVerSlimeScouringTS(.KASeeLaptopPerfectTS)
                } else {
                    KAVerSlimeScouringTS(.KACallLineHatTS("Payment failed: \(KATeacherConcentrateTracksTS.error?.localizedDescription ?? "Unknown error")"))
                }
            @unknown default:
                KAVerSlimeScouringTS(.KACallLineHatTS("The App Store returned an unknown transaction state."))
            }
        }
    }

    private func KABridgeImageKnightTS(_ KATeacherConcentrateTracksTS: SKPaymentTransaction) {
        guard let KAIndexLagInfoTS = KATeacherConcentrateTracksTS.transactionIdentifier, !KAIndexLagInfoTS.isEmpty else {
            KAVerSlimeScouringTS(.KACallLineHatTS("The App Store did not return a transaction identifier. The transaction will be retried later.")); return
        }
        guard !KAElephantPrincePaintTS.contains(KAIndexLagInfoTS) else { return }
        if KASixDescFromTS(KAIndexLagInfoTS) {
            SKPaymentQueue.default().finishTransaction(KATeacherConcentrateTracksTS)
            KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("StoreKit1", "重复回调已确认验单成功，直接 finishTransaction：\(KAIndexLagInfoTS)")
            return
        }
        guard let KABoomArrivalDreamsTS else {
            KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("StoreKit1", "验单接口尚未配置，保留交易")
            return
        }
        guard let KACoatMorningSkyTS = KADetermineThemSnowingTS() else {
            KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("StoreKit1", "交易缺少订单上下文，视为重复或历史回调；不向用户显示支付失败弹窗：\(KAIndexLagInfoTS)")
            return
        }
        guard KACoatMorningSkyTS.KAShirtDreamsSixTS == KATeacherConcentrateTracksTS.payment.productIdentifier else {
            KAVerSlimeScouringTS(.KACallLineHatTS("The purchased product does not match the order. Verification will be retried later.")); return
        }
        guard let KASeeFlowerUseTS = KAPencilFlyOctopusTS() else {
            if !KAAcheMusicDragonTS.contains(where: { $0 === KATeacherConcentrateTracksTS }) { KAAcheMusicDragonTS.append(KATeacherConcentrateTracksTS) }
            if KAMaxKnowWantTS == nil {
                KAVerSlimeScouringTS(.KAArrestBigBinTS("Refreshing the App Store receipt…"))
                let KAScouringTracksClientTS = SKReceiptRefreshRequest()
                KAMaxKnowWantTS = KAScouringTracksClientTS
                KAScouringTracksClientTS.delegate = self
                KAScouringTracksClientTS.start()
            }
            return
        }
        let KAOnlineMsgShirtTS = KADiscussionPigCityTS(KAGoodNetCoffeeTS: KACoatMorningSkyTS.KAGoodNetCoffeeTS)
        KAElephantPrincePaintTS.insert(KAIndexLagInfoTS)
        KAVerSlimeScouringTS(.KAArrestBigBinTS("Payment completed. Verifying purchase…"))
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("StoreKit1", "调用 3.2.5 验单；收据与订单信息已脱敏")
        Task {
            do {
                try await KABoomArrivalDreamsTS.KAGrazeTracksDisTS(KAIndexLagInfoTS: KAIndexLagInfoTS,
                                                            KASeeFlowerUseTS: KASeeFlowerUseTS,
                                                            KAOnlineMsgShirtTS: KAOnlineMsgShirtTS)
                await MainActor.run {
                    self.KAElephantPrincePaintTS.remove(KAIndexLagInfoTS)
                    guard let KAEysPotionOptionTS = KACoatMorningSkyTS.KABeeEarthSayTS,
                          let KABeeEarthSayTS = Decimal(string: KAEysPotionOptionTS),
                          let KAListAnySauceTS = KACoatMorningSkyTS.KAListAnySauceTS,
                          !KAListAnySauceTS.isEmpty else {
                        self.KAVerSlimeScouringTS(.KACallLineHatTS("The purchase was verified, but its price or currency is missing. The transaction will be retried later."))
                        return
                    }
                    self.KAFuncVcGoldTS?.KAOnlineAngerDearTS(
                        KABeeEarthSayTS: KABeeEarthSayTS,
                        KAListAnySauceTS: KAListAnySauceTS
                    )
                    self.KABrushColonialCallTS(KAIndexLagInfoTS)
                    SKPaymentQueue.default().finishTransaction(KATeacherConcentrateTracksTS)
                    self.KACloudLineBusyTS()
                    KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("StoreKit1", "验单 code=0000；触发 Purchase 后已 finishTransaction")
                    self.KAVerSlimeScouringTS(.KALabelDegreeWoodTS("Payment successful"))
                }
            } catch {
                await MainActor.run {
                    self.KAElephantPrincePaintTS.remove(KAIndexLagInfoTS)
                    KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("StoreKit1", "验单失败：\(error.localizedDescription)。交易未 finish")
                    self.KAVerSlimeScouringTS(.KACallLineHatTS("Payment completed, but verification failed: \(error.localizedDescription)\nThe transaction will be retried later."))
                }
            }
        }
    }

    private func KAPencilFlyOctopusTS() -> String? {
        guard let KAZeroLiefChanceTS = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: KAZeroLiefChanceTS.path),
              let KADesertCountPaintTS = try? Data(contentsOf: KAZeroLiefChanceTS), !KADesertCountPaintTS.isEmpty else { return nil }
        return KADesertCountPaintTS.base64EncodedString()
    }

    private func KADiscussionPigCityTS(KAGoodNetCoffeeTS: String) -> String {
        guard let KADesertCountPaintTS = try? JSONSerialization.data(withJSONObject: ["orderCode": KAGoodNetCoffeeTS], options: [.sortedKeys]) else { return "" }
        return String(decoding: KADesertCountPaintTS, as: UTF8.self)
    }

    private func KADolphinDownSkyTS(_ KAIndexAthleticInfoTS: KAOnlinePlaneTipTS) {
        if let KADesertCountPaintTS = try? JSONEncoder().encode(KAIndexAthleticInfoTS) {
            UserDefaults.standard.set(KADesertCountPaintTS, forKey: KAPantsDialogueBigTS)
        }
    }

    private func KADetermineThemSnowingTS() -> KAOnlinePlaneTipTS? {
        guard let KADesertCountPaintTS = UserDefaults.standard.data(forKey: KAPantsDialogueBigTS) else { return nil }
        return try? JSONDecoder().decode(KAOnlinePlaneTipTS.self, from: KADesertCountPaintTS)
    }

    private func KACloudLineBusyTS() { UserDefaults.standard.removeObject(forKey: KAPantsDialogueBigTS) }

    private func KASixDescFromTS(_ KAIndexLagInfoTS: String) -> Bool {
        let KAMemoryHeroLineTS = UserDefaults.standard.stringArray(forKey: KAPhoneClearDelTS) ?? []
        return KAMemoryHeroLineTS.contains(KAIndexLagInfoTS)
    }

    private func KABrushColonialCallTS(_ KAIndexLagInfoTS: String) {
        var KAMemoryHeroLineTS = UserDefaults.standard.stringArray(forKey: KAPhoneClearDelTS) ?? []
        guard !KAMemoryHeroLineTS.contains(KAIndexLagInfoTS) else { return }
        KAMemoryHeroLineTS.append(KAIndexLagInfoTS)
        UserDefaults.standard.set(KAMemoryHeroLineTS, forKey: KAPhoneClearDelTS)
    }

    func KAThreeArsenalQuizzesTS(_ KADirectorBorderDependingTS: String) -> Bool {
        let KAMemoryHeroLineTS = UserDefaults.standard.stringArray(forKey: KAZeroTracksGoldTS) ?? []
        return KAMemoryHeroLineTS.contains(KADirectorBorderDependingTS)
    }

    private func KADatePencilOrderTS(_ KADirectorBorderDependingTS: String) {
        var KAMemoryHeroLineTS = UserDefaults.standard.stringArray(forKey: KAZeroTracksGoldTS) ?? []
        guard !KAMemoryHeroLineTS.contains(KADirectorBorderDependingTS) else { return }
        KAMemoryHeroLineTS.append(KADirectorBorderDependingTS)
        UserDefaults.standard.set(KAMemoryHeroLineTS, forKey: KAZeroTracksGoldTS)
    }

    private func KAVerSlimeScouringTS(_ KATigerCharacterMyTS: KABinMomentsFuncTS) {
        DispatchQueue.main.async { [weak self] in self?.KACharacterThereEveryTS?(KATigerCharacterMyTS) }
    }
}
