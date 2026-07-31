import UIKit
import SnapKit
import PhotosUI
import AVKit

enum KavoColor {
    static let canvas = UIColor(hex: 0xFBF7F0)
    static let surface = UIColor(hex: 0xF5F1EA)
    static let surfaceMuted = UIColor(hex: 0xEBE5DA)
    static let elevated = UIColor.white
    static let primary = UIColor(hex: 0xEB754B)
    static let primaryPressed = UIColor(hex: 0xD9633D)
    static let primaryDisabled = UIColor(hex: 0xE8B8A7)
    static let textPrimary = UIColor(hex: 0x11100D)
    static let textSecondary = UIColor(hex: 0x75644F)
    static let textTertiary = UIColor(hex: 0xA9A197)
    static let border = UIColor(hex: 0xD8D4CD)
    static let lavender = UIColor(hex: 0xE9D7F4)
    static let like = UIColor(hex: 0xFF4F7D)
    static let info = UIColor(hex: 0x73A9D8)
    static let success = UIColor(hex: 0x4F9B68)
    static let warning = UIColor(hex: 0xD99532)
    static let danger = UIColor(hex: 0xD94B45)
    static let coin = UIColor(hex: 0xE9A925)
}

enum KavoFont {
    static let display = UIFont.preferredFont(forTextStyle: .largeTitle).with(weight: .bold)
    static let title1 = UIFont.preferredFont(forTextStyle: .title1).with(weight: .bold)
    static let title2 = UIFont.preferredFont(forTextStyle: .title2).with(weight: .bold)
    static let title3 = UIFont.preferredFont(forTextStyle: .title3).with(weight: .semibold)
    static let headline = UIFont.preferredFont(forTextStyle: .headline)
    static let body = UIFont.preferredFont(forTextStyle: .body)
    static let callout = UIFont.preferredFont(forTextStyle: .callout).with(weight: .medium)
    static let caption = UIFont.preferredFont(forTextStyle: .caption1)
}

enum KavoSpace {
    static let x1: CGFloat = 4
    static let x2: CGFloat = 8
    static let x3: CGFloat = 12
    static let x4: CGFloat = 16
    static let page: CGFloat = 20
    static let x6: CGFloat = 24
    static let x8: CGFloat = 32
}

private let kavoDefaultAvatar: UIImage = {
    let size = CGSize(width: 120, height: 120)
    return UIGraphicsImageRenderer(size: size).image { context in
        UIColor(hex: 0xE5E5EA).setFill()
        context.cgContext.fill(CGRect(origin: .zero, size: size))
        let configuration = UIImage.SymbolConfiguration(pointSize: 55, weight: .regular)
        let symbol = UIImage(systemName: "person.fill", withConfiguration: configuration)?
            .withTintColor(UIColor(hex: 0x8E8E93), renderingMode: .alwaysOriginal)
        let symbolSize = symbol?.size ?? .zero
        symbol?.draw(
            at: CGPoint(
                x: (size.width - symbolSize.width) / 2,
                y: (size.height - symbolSize.height) / 2 + 5
            )
        )
    }
}()

func kavoDefaultAvatarImage() -> UIImage {
    kavoDefaultAvatar
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255, blue: CGFloat(hex & 0xff) / 255, alpha: 1)
    }
}

extension UIFont {
    func with(weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

extension UIView {
    func pin(to other: UIView, inset: UIEdgeInsets = .zero) {
        snp.makeConstraints { make in
            make.top.equalTo(other).inset(inset.top)
            make.leading.equalTo(other).inset(inset.left)
            make.trailing.equalTo(other).inset(inset.right)
            make.bottom.equalTo(other).inset(inset.bottom)
        }
    }

    func rounded(_ radius: CGFloat = 12, border: UIColor? = nil, width: CGFloat = 1) {
        layer.cornerRadius = radius
        clipsToBounds = true
        if let border {
            layer.borderColor = border.cgColor
            layer.borderWidth = width
        }
    }
}

@discardableResult
func installAlertBackground(in container: UIView) -> UIImageView {
    container.backgroundColor = .clear
    let background = UIImageView(image: UIImage(named: "alert_bg"))
    background.contentMode = .scaleToFill
    background.clipsToBounds = true
    container.insertSubview(background, at: 0)
    background.snp.makeConstraints { $0.edges.equalToSuperview() }
    return background
}

final class KavoAlertViewController: UIViewController {
    private let alertTitle: String
    private let alertMessage: String?
    private let primaryTitle: String
    private let showsCancel: Bool
    private let destructive: Bool
    private let primaryAction: (() -> Void)?

    init(
        title: String,
        message: String?,
        primaryTitle: String = "OK",
        showsCancel: Bool = false,
        destructive: Bool = false,
        primaryAction: (() -> Void)? = nil
    ) {
        alertTitle = title
        alertMessage = message
        self.primaryTitle = primaryTitle
        self.showsCancel = showsCancel
        self.destructive = destructive
        self.primaryAction = primaryAction
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)

        let card = UIView()
        installAlertBackground(in: card)
        let titleLabel = UILabel()
        titleLabel.text = alertTitle
        titleLabel.font = KavoFont.title2
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        let messageLabel = UILabel()
        messageLabel.text = alertMessage
        messageLabel.font = KavoFont.body
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.isHidden = alertMessage?.isEmpty != false

        let primary = KavoButton(primaryTitle, style: destructive ? .destructive : .primary)
        primary.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.dismiss(animated: true) { self.primaryAction?() }
        }, for: .touchUpInside)

        var buttons = [UIView]()
        if showsCancel {
            let cancel = KavoButton("Cancel", style: .outline)
            cancel.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
            buttons.append(cancel)
        }
        buttons.append(primary)
        let buttonStack = UIStackView(arrangedSubviews: buttons)
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        let content = UIStackView(arrangedSubviews: [titleLabel, messageLabel, buttonStack])
        content.axis = .vertical
        content.spacing = 17

        view.addSubview(card)
        card.addSubview(content)
        card.snp.makeConstraints {
            $0.centerY.equalToSuperview().offset(-40)
            $0.leading.trailing.equalToSuperview().inset(14)
            $0.height.greaterThanOrEqualTo(233)
        }
        content.snp.makeConstraints {
            $0.top.equalToSuperview().offset(42)
            $0.leading.trailing.equalToSuperview().inset(28)
            $0.bottom.equalToSuperview().inset(28)
        }
        buttonStack.snp.makeConstraints { $0.height.equalTo(50) }
    }
}

final class KavoButton: UIButton {
    enum Style { case primary, outline, compact, destructive }

    init(_ title: String, style: Style = .primary) {
        super.init(frame: .zero)
        configuration = .filled()
        configuration?.title = title
        configuration?.cornerStyle = .medium
        configuration?.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18)
        titleLabel?.font = KavoFont.headline
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(style == .compact ? 44 : 52) }
        switch style {
        case .primary:
            configuration?.baseBackgroundColor = KavoColor.primary
            configuration?.baseForegroundColor = .white
        case .outline:
            configuration?.baseBackgroundColor = KavoColor.elevated
            configuration?.baseForegroundColor = KavoColor.textPrimary
            layer.borderColor = KavoColor.textPrimary.cgColor
            layer.borderWidth = 2
            layer.cornerRadius = 12
        case .compact:
            configuration?.baseBackgroundColor = KavoColor.primary
            configuration?.baseForegroundColor = .white
        case .destructive:
            configuration?.baseBackgroundColor = KavoColor.danger
            configuration?.baseForegroundColor = .white
        }
        accessibilityLabel = title
    }

    required init?(coder: NSCoder) { nil }
}

final class KavoTextField: UITextField {
    init(placeholder: String) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        font = KavoFont.body
        textColor = KavoColor.textPrimary
        backgroundColor = KavoColor.elevated
        borderStyle = .none
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = KavoColor.border.cgColor
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        leftViewMode = .always
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(48) }
        adjustsFontForContentSizeCategory = true
    }
    required init?(coder: NSCoder) { nil }
}

final class KavoImagePickerCoordinator: NSObject,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    PHPickerViewControllerDelegate {

    var onImagesPicked: (([UIImage]) -> Void)?
    private weak var presenter: UIViewController?
    private var selectionLimit = 1

    func presentSourceSheet(from presenter: UIViewController, sourceView: UIView, selectionLimit: Int = 1) {
        self.presenter = presenter
        self.selectionLimit = max(1, selectionLimit)

        let sheet = UIAlertController(title: "Add Photo", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.presentCamera()
        })
        sheet.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.presentPhotoLibrary()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }
        presenter.present(sheet, animated: true)
    }

    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let alert = KavoAlertViewController(
                title: "Camera unavailable",
                message: "This device does not have an available camera."
            )
            presenter?.present(alert, animated: true)
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = self
        presenter?.present(picker, animated: true)
    }

    private func presentPhotoLibrary() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = selectionLimit
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        presenter?.present(picker, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        picker.dismiss(animated: true) { [weak self] in
            if let image { self?.onImagesPicked?([image]) }
        }
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !results.isEmpty else {
            picker.dismiss(animated: true)
            return
        }
        let group = DispatchGroup()
        let lock = NSLock()
        var indexedImages: [(Int, UIImage)] = []
        for (index, result) in results.enumerated() where result.itemProvider.canLoadObject(ofClass: UIImage.self) {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                defer { group.leave() }
                guard let image = object as? UIImage else { return }
                lock.lock()
                indexedImages.append((index, image))
                lock.unlock()
            }
        }
        group.notify(queue: .main) { [weak self, weak picker] in
            let images = indexedImages.sorted { $0.0 < $1.0 }.map(\.1)
            picker?.dismiss(animated: true) {
                if !images.isEmpty { self?.onImagesPicked?(images) }
            }
        }
    }
}

final class KavoCardView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = KavoColor.surface
        rounded(16)
    }
    required init?(coder: NSCoder) { nil }
}

final class KavoStateView: UIView {
    init(symbol: String, title: String, detail: String) {
        super.init(frame: .zero)
        let image = UIImageView(image: UIImage(systemName: symbol))
        image.tintColor = KavoColor.primary
        image.contentMode = .scaleAspectFit
        image.snp.makeConstraints { $0.height.equalTo(48) }
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = KavoFont.title3
        titleLabel.textAlignment = .center
        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = KavoFont.body
        detailLabel.textColor = KavoColor.textSecondary
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0
        let stack = UIStackView(arrangedSubviews: [image, titleLabel, detailLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        addSubview(stack)
        stack.pin(to: self)
    }
    required init?(coder: NSCoder) { nil }
}

final class VideoPlaybackViewController: UIViewController {
    private let player: AVPlayer
    private let playerController = AVPlayerViewController()

    init(url: URL) {
        player = AVPlayer(url: url)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { nil }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        playerController.player = player
        playerController.showsPlaybackControls = true
        addChild(playerController)
        view.addSubview(playerController.view)
        playerController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        playerController.didMove(toParent: self)

        let back = UIButton(type: .system)
        back.setImage(
            UIImage(
                systemName: "chevron.left",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
            ),
            for: .normal
        )
        back.tintColor = .white
        back.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        back.layer.cornerRadius = 22
        back.accessibilityLabel = "Back"
        back.addAction(UIAction { [weak self] _ in self?.close() }, for: .touchUpInside)
        view.addSubview(back)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.size.equalTo(44)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
        player.seek(to: .zero)
    }

    @objc private func close() {
        player.pause()
        player.seek(to: .zero)
        dismiss(animated: true)
    }
}

class KavoViewController: UIViewController {
    let repository = MockRepository.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = KavoColor.canvas
        navigationItem.backButtonDisplayMode = .minimal
        NotificationCenter.default.addObserver(self, selector: #selector(repositoryDidChange), name: MockRepository.changed, object: nil)
    }

    @objc func repositoryDidChange() {}

    func showMessage(_ title: String, message: String? = nil) {
        present(KavoAlertViewController(title: title, message: message), animated: true)
    }

    @discardableResult
    func requireSignedIn() -> Bool {
        guard !AuthSessionStore.isSignedIn else { return true }
        presentLoginRequired()
        return false
    }

    func presentLoginRequired() {
        guard presentedViewController == nil else { return }
        present(
            KavoDecisionModalViewController(kind: .loginRequired, primaryTitle: "Sure") { [weak self] in
                guard let self,
                      let scene = view.window?.windowScene?.delegate as? SceneDelegate else { return }
                let welcome = WelcomeViewController()
                let signIn = AuthFormViewController(mode: .signIn)
                let navigation = UINavigationController(rootViewController: welcome)
                navigation.setViewControllers([welcome, signIn], animated: false)
                scene.window?.rootViewController = navigation
            },
            animated: true
        )
    }

    func confirm(title: String, message: String? = nil, actionTitle: String, destructive: Bool = false, action: @escaping () -> Void) {
        present(
            KavoAlertViewController(
                title: title,
                message: message,
                primaryTitle: actionTitle,
                showsCancel: true,
                destructive: destructive,
                primaryAction: action
            ),
            animated: true
        )
    }
}
