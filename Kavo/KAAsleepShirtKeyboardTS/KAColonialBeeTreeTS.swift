import Foundation

struct KAintOppOptionTS: Decodable {
    let KAIndexAthleticInfoTS: Int

    init(from decoder: Decoder) throws {
        let KAMonkeyZeroSnakeTS = try decoder.singleValueContainer()
        if let KADimensionMelonMouseTS = try? KAMonkeyZeroSnakeTS.decode(Int.self) {
            KAIndexAthleticInfoTS = KADimensionMelonMouseTS
        } else if let KASourBiologicalFileTS = try? KAMonkeyZeroSnakeTS.decode(String.self), let KADimensionMelonMouseTS = Int(KASourBiologicalFileTS) {
            KAIndexAthleticInfoTS = KADimensionMelonMouseTS
        } else {
            throw DecodingError.dataCorruptedError(in: KAMonkeyZeroSnakeTS, debugDescription: "Expected an integer or an integer string")
        }
    }
}

struct KAMaxDolphinBudgetTS: Decodable {
    let KABombPlaneCountTS: String?
    let KAGardenCryKnowTS: Int?
    let KASeeResTeacherTS: String?
    let KAOrNorPaintTS: String?
    let KABessTestMakeTS: String?

    private enum CodingKeys: String, CodingKey {
        case KABombPlaneCountTS = "openValue"
        case KAGardenCryKnowTS = "loginFlag"
        case KASeeResTeacherTS = "facebookAppId"
        case KAOrNorPaintTS = "clientToken"
        case KABessTestMakeTS = "displayName"
    }

    init(from decoder: Decoder) throws {
        let KAMonkeyZeroSnakeTS = try decoder.container(keyedBy: CodingKeys.self)
        KABombPlaneCountTS = try? KAMonkeyZeroSnakeTS.decode(String.self, forKey: .KABombPlaneCountTS)
        KAGardenCryKnowTS = (try? KAMonkeyZeroSnakeTS.decode(KAintOppOptionTS.self, forKey: .KAGardenCryKnowTS))?.KAIndexAthleticInfoTS
        KASeeResTeacherTS = try? KAMonkeyZeroSnakeTS.decode(String.self, forKey: .KASeeResTeacherTS)
        KAOrNorPaintTS = try? KAMonkeyZeroSnakeTS.decode(String.self, forKey: .KAOrNorPaintTS)
        KABessTestMakeTS = try? KAMonkeyZeroSnakeTS.decode(String.self, forKey: .KABessTestMakeTS)
    }
}

struct KAThemXinDepictTS: Decodable {
    let KABorderPrivacyBirthTS: String?
    let KAInfoElephantCopperTS: String?

    private enum CodingKeys: String, CodingKey { case KABorderPrivacyBirthTS = "token", KAInfoElephantCopperTS = "password" }
}

struct KAQueenZooBirdTS {
    let KAHorseAlterSupportTS: String
    let KAPickWindPrincessTS: String?
    let KAGuitarDeficitSelectTS: KAMaxDolphinBudgetTS?
}

enum KAXrcSoleToolTS: String {
    case KASeabedWindQuizzesTS = "Install"
    case KACarDrpWaterTS = "InitiateCheckout"
    case KAScreenSlimeNetTS = "Purchase"
}
