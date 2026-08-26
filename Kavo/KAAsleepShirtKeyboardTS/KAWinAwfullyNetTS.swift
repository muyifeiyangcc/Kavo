import Foundation

enum KATerCoffeeFreeTS: LocalizedError {
    case KAMakeTableMagicTS, KALovingNorEraserTS, KADeficitPaintHorseTS(Int32), KATrainDevastateDeficitTS
    var errorDescription: String? {
        switch self {
        case .KAMakeTableMagicTS: return "AES key/iv 必须各为 16 字节"
        case .KALovingNorEraserTS: return "服务端密文不是合法十六进制字符串"
        case .KADeficitPaintHorseTS(let KAMagicDiscussionTheTS): return "AES 运算失败：\(KAMagicDiscussionTheTS)"
        case .KATrainDevastateDeficitTS: return "解密结果不是 UTF-8"
        }
    }
}

struct KAWinAwfullyNetTS {
    let KAVineDataDialectTS: Data
    let KADragonCeillingCallTS: Data

    init(KAVineDataDialectTS: String, KADragonCeillingCallTS: String) throws {
        self.KAVineDataDialectTS = Data(KAVineDataDialectTS.utf8)
        self.KADragonCeillingCallTS = Data(KADragonCeillingCallTS.utf8)
        guard self.KAVineDataDialectTS.count == kCCKeySizeAES128, self.KADragonCeillingCallTS.count == kCCBlockSizeAES128 else {
            throw KATerCoffeeFreeTS.KAMakeTableMagicTS
        }
    }

    func KAInterAlterSeeTS(_ KAKnightMonkeyUpTS: String) throws -> String {
        try KAWantMomentTimeTS(Data(KAKnightMonkeyUpTS.utf8), KAOffCentralDemonstrateTS: CCOperation(kCCEncrypt)).KAAwfullyArgAthleteTS
    }

    func KAFishMelonKingTS(_ KAIdahoQueYourTS: String) throws -> String {
        guard let KADesertCountPaintTS = Data(KAOnlyWindDepictTS: KAIdahoQueYourTS) else { throw KATerCoffeeFreeTS.KALovingNorEraserTS }
        let KASupportEasyShirtTS = try KAWantMomentTimeTS(KADesertCountPaintTS, KAOffCentralDemonstrateTS: CCOperation(kCCDecrypt))
        guard let KAIndexAthleticInfoTS = String(data: KASupportEasyShirtTS, encoding: .utf8) else { throw KATerCoffeeFreeTS.KATrainDevastateDeficitTS }
        return KAIndexAthleticInfoTS
    }

    private func KAWantMomentTimeTS(_ KAWoodHugLabelTS: Data, KAOffCentralDemonstrateTS: CCOperation) throws -> Data {
        var KAAthleticInJustTS = Data(count: KAWoodHugLabelTS.count + kCCBlockSizeAES128)
        let KAClientPassDrpTS = KAAthleticInJustTS.count
        var KAMyListShoesTS = 0
        let KAMagicDiscussionTheTS = KAAthleticInJustTS.withUnsafeMutableBytes { KADevLastInsectTS in
            KAWoodHugLabelTS.withUnsafeBytes { KAYourVocabularyBlindTS in
                KAVineDataDialectTS.withUnsafeBytes { KACameraPresentUntilTS in
                    KADragonCeillingCallTS.withUnsafeBytes { KAIndexEnoughMelonTS in
                        CCCrypt(KAOffCentralDemonstrateTS, CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding),
                                KACameraPresentUntilTS.baseAddress, KAVineDataDialectTS.count, KAIndexEnoughMelonTS.baseAddress,
                                KAYourVocabularyBlindTS.baseAddress, KAWoodHugLabelTS.count, KADevLastInsectTS.baseAddress,
                                KAClientPassDrpTS, &KAMyListShoesTS)
                    }
                }
            }
        }
        guard KAMagicDiscussionTheTS == kCCSuccess else { throw KATerCoffeeFreeTS.KADeficitPaintHorseTS(KAMagicDiscussionTheTS) }
        KAAthleticInJustTS.removeSubrange(KAMyListShoesTS..<KAAthleticInJustTS.count)
        return KAAthleticInJustTS
    }
}

private extension Data {
    var KAAwfullyArgAthleteTS: String { map { String(format: "%02x", $0) }.joined() }

    init?(KAOnlyWindDepictTS: String) {
        guard KAOnlyWindDepictTS.count.isMultiple(of: 2), KAOnlyWindDepictTS.allSatisfy({ $0.isHexDigit }) else { return nil }
        self.init()
        reserveCapacity(KAOnlyWindDepictTS.count / 2)
        var KAConcentrateTipJobTS = KAOnlyWindDepictTS.startIndex
        while KAConcentrateTipJobTS < KAOnlyWindDepictTS.endIndex {
            let KAOurCastleDearTS = KAOnlyWindDepictTS.index(KAConcentrateTipJobTS, offsetBy: 2)
            guard let KADownFishintTS = UInt8(KAOnlyWindDepictTS[KAConcentrateTipJobTS..<KAOurCastleDearTS], radix: 16) else { return nil }
            append(KADownFishintTS)
            KAConcentrateTipJobTS = KAOurCastleDearTS
        }
    }
}

