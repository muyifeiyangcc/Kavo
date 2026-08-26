import UIKit

@MainActor
final class KADevComesPhotoTS: UIViewController {
    private let KAIronMomentObsessionTS: KAOilTrialsGrazeTS
    private let KAUpMaxDependTS: UIImage?
    private let KADespiteGrazeFunTS: UIImage?
    private var KAEnhanceHouseCanTS: URL?
    private let KABlindJoyChanceTS = UIButton(type: .system)
    private let KACenterMirrorComputerTS = UIView()
    private let KADragonPantsBinTS = UIActivityIndicatorView(style: .large)
    private let KAWoodPassFlatTS = UILabel()
    private var KATestShirtBlightTS = false
    private var KAWindowCameraCentralTS = false
    private var KAPhotoOrangeHatTS: KADimensionTigerBessTS?

    init(KAIronMomentObsessionTS: KAOilTrialsGrazeTS,
         KAFunBloomInTS: KAToolShieldMsgTS,
         KAUpMaxDependTS: UIImage? = nil,
         KADespiteGrazeFunTS: UIImage? = nil) {
        self.KAIronMomentObsessionTS = KAIronMomentObsessionTS
        switch KAFunBloomInTS {
        case .KAJoySlowDearTS:
            KAEnhanceHouseCanTS = nil
        case .KANotebookMayUseTS(let KAZeroLiefChanceTS):
            KAEnhanceHouseCanTS = KAZeroLiefChanceTS
        }
        self.KAUpMaxDependTS = KAUpMaxDependTS
        self.KADespiteGrazeFunTS = KADespiteGrazeFunTS
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        KAWinBlowBeenTS()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !KATestShirtBlightTS, let KAEnhanceHouseCanTS else { return }
        KATestShirtBlightTS = true
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("登录页", "非首次登录：已显示登录页，在页面上自动展示 Loading 并预加载 H5")
        KABlowCarColonialTS(KAZeroLiefChanceTS: KAEnhanceHouseCanTS)
    }

    private func KAWinBlowBeenTS() {
        view.backgroundColor = .systemBackground
        if let KAUpMaxDependTS {
            let KAMountainAskBusyTS = UIImageView(image: KAUpMaxDependTS)
            KAMountainAskBusyTS.translatesAutoresizingMaskIntoConstraints = false
            KAMountainAskBusyTS.contentMode = .scaleAspectFill
            view.addSubview(KAMountainAskBusyTS)
            NSLayoutConstraint.activate([
                KAMountainAskBusyTS.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                KAMountainAskBusyTS.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                KAMountainAskBusyTS.topAnchor.constraint(equalTo: view.topAnchor),
                KAMountainAskBusyTS.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        KABlindJoyChanceTS.setTitle("Sign In", for: .normal)
        KABlindJoyChanceTS.setTitleColor(.white, for: .normal)
        KABlindJoyChanceTS.titleLabel?.font = KavoFont.headline
        KABlindJoyChanceTS.backgroundColor = KavoColor.primary
        KABlindJoyChanceTS.layer.cornerRadius = 12
        KABlindJoyChanceTS.layer.masksToBounds = true
        KABlindJoyChanceTS.layer.borderWidth = 0
        KABlindJoyChanceTS.configuration = nil
        KABlindJoyChanceTS.addTarget(self, action: #selector(KAPerfectRiverMemoryTS), for: .touchUpInside)
        KABlindJoyChanceTS.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(KABlindJoyChanceTS)

        KACenterMirrorComputerTS.translatesAutoresizingMaskIntoConstraints = false
        KACenterMirrorComputerTS.backgroundColor = .clear
        KACenterMirrorComputerTS.isHidden = true
        KADragonPantsBinTS.translatesAutoresizingMaskIntoConstraints = false
        KADragonPantsBinTS.color = .black
        KAWoodPassFlatTS.text = "Loading…"
        KAWoodPassFlatTS.textColor = .black
        KAWoodPassFlatTS.font = .systemFont(ofSize: 16, weight: .semibold)
        KAWoodPassFlatTS.translatesAutoresizingMaskIntoConstraints = false
        let KAArgSweetBeeTS = UIStackView(arrangedSubviews: [KADragonPantsBinTS, KAWoodPassFlatTS])
        KAArgSweetBeeTS.axis = .vertical
        KAArgSweetBeeTS.alignment = .center
        KAArgSweetBeeTS.spacing = 14
        KAArgSweetBeeTS.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(KACenterMirrorComputerTS)
        KACenterMirrorComputerTS.addSubview(KAArgSweetBeeTS)

        NSLayoutConstraint.activate([
            KABlindJoyChanceTS.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            KABlindJoyChanceTS.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            KABlindJoyChanceTS.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -48),
            KABlindJoyChanceTS.heightAnchor.constraint(equalToConstant: 52),
            KACenterMirrorComputerTS.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            KACenterMirrorComputerTS.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            KACenterMirrorComputerTS.topAnchor.constraint(equalTo: view.topAnchor),
            KACenterMirrorComputerTS.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            KAArgSweetBeeTS.centerXAnchor.constraint(equalTo: KACenterMirrorComputerTS.centerXAnchor),
            KAArgSweetBeeTS.centerYAnchor.constraint(equalTo: KACenterMirrorComputerTS.centerYAnchor)
        ])
    }

    @objc private func KAPerfectRiverMemoryTS() {
        guard !KAWindowCameraCentralTS else { return }
        KAPeachCentralDialogueTS(true)
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("登录页", "首次登录：点击 Sign In 后在登录页展示 Loading，并开始登录及预加载 H5")
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let KAZeroLiefChanceTS = try await KAIronMomentObsessionTS.KAEasyWindowMinTS()
                KABlowCarColonialTS(KAZeroLiefChanceTS: KAZeroLiefChanceTS, KAEnoughOceanPotionTS: true)
            } catch {
                KASixDisplayListTS(error)
            }
        }
    }

    private func KABlowCarColonialTS(KAZeroLiefChanceTS: URL, KAEnoughOceanPotionTS: Bool = false) {
        guard KAPhotoOrangeHatTS == nil else { return }
        if !KAEnoughOceanPotionTS { KAPeachCentralDialogueTS(true) }

        let KAPantsClockNorTS = KADimensionTigerBessTS(
            KAZeroLiefChanceTS: KAZeroLiefChanceTS,
            KABoomArrivalDreamsTS: KAIronMomentObsessionTS.KABoomArrivalDreamsTS,
            KAFuncVcGoldTS: KAIronMomentObsessionTS.KAFuncVcGoldTS,
            KAUpMaxDependTS: KADespiteGrazeFunTS,
            KAJuiceComesAthleteTS: { [weak self] in self?.KADearDenyBookTS() }
        )
        KAPantsClockNorTS.modalPresentationStyle = .fullScreen
        KAPhotoOrangeHatTS = KAPantsClockNorTS
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("H5", "先无动画 present WebView，进入 Window 后再开始加载 H5")
        present(KAPantsClockNorTS, animated: false) { [weak self, weak KAPantsClockNorTS] in
            guard let self, let KAPantsClockNorTS,
                  KAPhotoOrangeHatTS === KAPantsClockNorTS else { return }
            KAPeachCentralDialogueTS(false)
        }
    }

    private func KAPeachCentralDialogueTS(_ KAArrestBigBinTS: Bool) {
        KAWindowCameraCentralTS = KAArrestBigBinTS
        KACenterMirrorComputerTS.isHidden = !KAArrestBigBinTS
        KABlindJoyChanceTS.isHidden = KAArrestBigBinTS
        KABlindJoyChanceTS.isEnabled = !KAArrestBigBinTS
        if KAArrestBigBinTS { KADragonPantsBinTS.startAnimating() }
        else { KADragonPantsBinTS.stopAnimating() }
    }

    private func KASixDisplayListTS(_ KAIndexChangeBridgeTS: Error) {
        KADespitePotionBigTS.KAInterCentralDisplayTS.KABoomGoldMountainTS("登录/H5失败", KAIndexChangeBridgeTS.localizedDescription)
        KAEnhanceHouseCanTS = nil
        KAPeachCentralDialogueTS(false)
        guard presentedViewController == nil else { return }
        let KAGliderBlindOnlineTS = UIAlertController(title: "加载失败",
                                              message: KAIndexChangeBridgeTS.localizedDescription,
                                              preferredStyle: .alert)
        KAGliderBlindOnlineTS.addAction(UIAlertAction(title: "确定", style: .default))
        present(KAGliderBlindOnlineTS, animated: true)
    }

    private func KADearDenyBookTS() {
        KAIronMomentObsessionTS.KAFlowerProtectZeroTS()
        let KAPantsClockNorTS = KAPhotoOrangeHatTS
        KAPantsClockNorTS?.dismiss(animated: false) { [weak self] in
            guard let self else { return }
            KAPhotoOrangeHatTS = nil
            KAEnhanceHouseCanTS = nil
            KATestShirtBlightTS = true
            KAPeachCentralDialogueTS(false)
        }
    }
}
