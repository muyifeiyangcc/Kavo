import Foundation

final class KADespitePotionBigTS: @unchecked Sendable {
    static let KAInterCentralDisplayTS = KADespitePotionBigTS()
    var KADeviceMirrorElephantTS: ((String) -> Void)?

    func KABoomGoldMountainTS(_ KALovingOppPassTS: String, _ KAPickWindPrincessTS: String) {
        let KACoatBoatWithTS = DateFormatter()
        KACoatBoatWithTS.dateFormat = "HH:mm:ss.SSS"
        let KAImageTrialsLoadTS = "[\(KACoatBoatWithTS.string(from: Date()))] [\(KALovingOppPassTS)] \(KAPickWindPrincessTS)"
        print(KAImageTrialsLoadTS)
        if Thread.isMainThread { KADeviceMirrorElephantTS?(KAImageTrialsLoadTS) }
        else { DispatchQueue.main.async { [weak self] in self?.KADeviceMirrorElephantTS?(KAImageTrialsLoadTS) } }
    }
}
