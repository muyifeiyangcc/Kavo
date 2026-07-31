import UIKit
import SnapKit
import CoreLocation
import Darwin

private enum AuthMetrics {
    static let pageInset: CGFloat = 18
    static let fieldHeight: CGFloat = 59
    static let actionHeight: CGFloat = 70
    static let fieldRadius: CGFloat = 10
    static let warmBackground = UIColor(hex: 0xFCF8F1)
    static let fieldBorder = UIColor(hex: 0xE6E0D7)
    static let placeholder = UIColor(hex: 0xC2BCB3)
    static let orange = UIColor(hex: 0xF0744B)
    static let darkRed = UIColor(hex: 0xA74B3D)
}

enum EULAConsentStore {
    private static let acceptedKey = "Kavo.EULA.Accepted"

    static var hasAccepted: Bool {
        UserDefaults.standard.bool(forKey: acceptedKey)
    }

    static func accept() {
        UserDefaults.standard.set(true, forKey: acceptedKey)
    }
}

enum AuthSessionStore {
    private enum Key {
        static let email = "Kavo.Auth.Email"
        static let password = "Kavo.Auth.Password"
        static let signedIn = "Kavo.Auth.SignedIn"
        static let testAccountSeeded = "Kavo.Auth.TestAccountSeeded"
        static let testAccountDeleted = "Kavo.Auth.TestAccountDeleted"
    }

    private static let defaults = UserDefaults.standard
    private static let testEmail = "123@gmail.com"
    private static let testPassword = "12345678"
    private static var guestMode = false
 
    static var isSignedIn: Bool {
        seedTestAccountIfNeeded()
        return defaults.bool(forKey: Key.signedIn) && storedEmail != nil
    }

    static var accountIdentifier: String {
        seedTestAccountIfNeeded()
        return guestMode ? "guest" : storedEmail ?? "guest"
    }

    static func register(email: String, password: String) -> Bool {
        seedTestAccountIfNeeded()
        guestMode = false
        let value = normalized(email)
        guard storedEmail != value else { return false }
        defaults.set(value, forKey: Key.email)
        defaults.set(password, forKey: Key.password)
        defaults.set(false, forKey: Key.signedIn)
        return true
    }

    static func signIn(email: String, password: String) -> Bool {
        seedTestAccountIfNeeded()
        let emailValue = normalized(email)
        if emailValue == testEmail,
           password == testPassword,
           !defaults.bool(forKey: Key.testAccountDeleted) {
            defaults.set(testEmail, forKey: Key.email)
            defaults.set(testPassword, forKey: Key.password)
            defaults.set(true, forKey: Key.signedIn)
            defaults.set(true, forKey: Key.testAccountSeeded)
            guestMode = false
            return true
        }
        guard storedEmail == emailValue,
              defaults.string(forKey: Key.password) == password else {
            return false
        }
        defaults.set(true, forKey: Key.signedIn)
        guestMode = false
        return true
    }

    static func enterGuestMode() {
        guestMode = true
        defaults.set(false, forKey: Key.signedIn)
    }

    static func resetPassword(email: String, newPassword: String) -> Bool {
        seedTestAccountIfNeeded()
        guard storedEmail == normalized(email) else { return false }
        defaults.set(newPassword, forKey: Key.password)
        defaults.set(false, forKey: Key.signedIn)
        return true
    }

    static func completeRegistration() {
        guard storedEmail != nil else { return }
        guestMode = false
        defaults.set(true, forKey: Key.signedIn)
    }

    static func signOut() {
        guestMode = false
        defaults.set(false, forKey: Key.signedIn)
    }

    static func deleteAccount() {
        guestMode = false
        if let email = storedEmail, normalized(email) == testEmail {
            defaults.set(true, forKey: Key.testAccountDeleted)
        }
        defaults.removeObject(forKey: Key.email)
        defaults.removeObject(forKey: Key.password)
        defaults.removeObject(forKey: Key.signedIn)
    }

    private static var storedEmail: String? {
        defaults.string(forKey: Key.email)
    }

    private static func seedTestAccountIfNeeded() {
        guard !defaults.bool(forKey: Key.testAccountDeleted) else { return }
        guard !defaults.bool(forKey: Key.testAccountSeeded) else { return }
        if defaults.string(forKey: Key.email) == nil {
            defaults.set(testEmail, forKey: Key.email)
            defaults.set(testPassword, forKey: Key.password)
            defaults.set(false, forKey: Key.signedIn)
        }
        defaults.set(true, forKey: Key.testAccountSeeded)
    }

    private static func normalized(_ email: String) -> String {
        email.filter { !$0.isWhitespace }.lowercased()
    }
}

private final class AuthField: UIView {
    let field = UITextField()
    private let titleLabel = UILabel()
    private var visibilityButton: UIButton?

    init(title: String, placeholder: String, secure: Bool = false, accessory: UIImage? = nil) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.textColor = AuthMetrics.orange
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        field.placeholder = placeholder
        field.isSecureTextEntry = secure
        field.font = .systemFont(ofSize: 15, weight: .semibold)
        field.textColor = KavoColor.textPrimary
        field.backgroundColor = .clear
        field.layer.cornerRadius = AuthMetrics.fieldRadius
        field.layer.borderWidth = 1
        field.layer.borderColor = AuthMetrics.fieldBorder.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 1))
        field.leftViewMode = .always
        if secure {
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 54, height: AuthMetrics.fieldHeight))
            let button = UIButton(type: .system)
            button.tintColor = AuthMetrics.darkRed
            button.frame = CGRect(x: 0, y: 0, width: 34, height: AuthMetrics.fieldHeight)
            button.accessibilityLabel = "Show password"
            button.addAction(UIAction { [weak self] _ in
                self?.togglePasswordVisibility()
            }, for: .touchUpInside)
            visibilityButton = button
            container.addSubview(button)
            field.rightView = container
            field.rightViewMode = .always
            updateVisibilityIcon()
        } else if let accessory {
            let image = UIImageView(image: accessory)
            image.tintColor = AuthMetrics.darkRed
            image.contentMode = .scaleAspectFit
            image.frame = CGRect(x: 0, y: 0, width: 42, height: 22)
            field.rightView = image
            field.rightViewMode = .always
        }
        addSubview(titleLabel)
        addSubview(field)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.height.equalTo(20)
        }
        field.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(13)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(AuthMetrics.fieldHeight)
        }
    }

    required init?(coder: NSCoder) { nil }

    private func togglePasswordVisibility() {
        let value = field.text
        field.isSecureTextEntry.toggle()
        field.text = value
        updateVisibilityIcon()
    }

    private func updateVisibilityIcon() {
        let name = field.isSecureTextEntry ? "eye.slash.fill" : "eye.fill"
        visibilityButton?.setImage(
            UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)),
            for: .normal
        )
        visibilityButton?.accessibilityLabel = field.isSecureTextEntry ? "Show password" : "Hide password"
        visibilityButton?.accessibilityValue = field.isSecureTextEntry ? "Password hidden" : "Password visible"
    }
}

private final class AuthBackButton: UIButton {
    init(action: UIAction) {
        super.init(frame: .zero)
        setImage(UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 23, weight: .medium)), for: .normal)
        tintColor = .black
        accessibilityLabel = "Back"
        addAction(action, for: .touchUpInside)
        snp.makeConstraints { $0.size.equalTo(44) }
    }
    required init?(coder: NSCoder) { nil }
}

private final class AuthBottomButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.black, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 21, weight: .bold)
        backgroundColor = .white
        layer.cornerRadius = 19
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 1
        layer.shadowRadius = 0
        snp.makeConstraints { $0.height.equalTo(AuthMetrics.actionHeight) }
    }
    required init?(coder: NSCoder) { nil }
}

private final class LegalLinksTextView: UITextView, UITextViewDelegate {
    var onOpenLink: ((String) -> Void)?

    init(prefix: String = "◉  ") {
        super.init(frame: .zero, textContainer: nil)
        backgroundColor = .clear
        isEditable = false
        isSelectable = true
        isScrollEnabled = false
        textAlignment = .center
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        delegate = self
        linkTextAttributes = [
            .foregroundColor: AuthMetrics.orange,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        let value = "\(prefix)By continuing you agree to our Terms of Service and\nPrivacy Policy"
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributed = NSMutableAttributedString(
            string: value,
            attributes: [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
        )
        let source = value as NSString
        attributed.addAttribute(
            .link,
            value: "kavo://terms",
            range: source.range(of: "Terms of Service")
        )
        attributed.addAttribute(
            .link,
            value: "kavo://privacy",
            range: source.range(of: "Privacy Policy")
        )
        attributedText = attributed
    }

    required init?(coder: NSCoder) { nil }

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        onOpenLink?(URL.host ?? "")
        return false
    }
}

private final class LegalConsentView: UIView {
    var onOpenLink: ((String) -> Void)? {
        didSet { links.onOpenLink = onOpenLink }
    }
    private(set) var isAccepted = false
    private let checkbox = UIButton(type: .custom)
    private let links = LegalLinksTextView(prefix: "")

    override init(frame: CGRect) {
        super.init(frame: frame)
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        checkbox.setImage(UIImage(systemName: "circle", withConfiguration: symbolConfiguration), for: .normal)
        checkbox.tintColor = .black
        checkbox.accessibilityLabel = "Accept Terms of Service and Privacy Policy"
        checkbox.addAction(UIAction { [weak self] _ in self?.toggle() }, for: .touchUpInside)
        let content = UIStackView(arrangedSubviews: [checkbox, links])
        content.axis = .horizontal
        content.alignment = .top
        content.spacing = 5
        addSubview(content)
        content.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        checkbox.snp.makeConstraints { $0.size.equalTo(20) }
        links.snp.makeConstraints { make in
            make.width.equalTo(290)
            make.height.equalTo(40)
        }
        updateSelectionStyle()
    }

    required init?(coder: NSCoder) { nil }

    private func toggle() {
        isAccepted.toggle()
        updateSelectionStyle()
    }

    private func updateSelectionStyle() {
        let name = isAccepted ? "largecircle.fill.circle" : "circle"
        checkbox.setImage(
            UIImage(
                systemName: name,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            ),
            for: .normal
        )
        checkbox.accessibilityValue = isAccepted ? "Selected" : "Not selected"
    }
}

final class LaunchViewController: UIViewController {
    var onFinished: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AuthMetrics.warmBackground
        let hero = UIImageView(image: UIImage(named: ""))
        hero.contentMode = .scaleAspectFill
        hero.clipsToBounds = true
        hero.alpha = 0;
        view.addSubview(hero)
        hero.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
        }
        DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in self?.onFinished?() }
    }
}

final class EULAViewController: KavoViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        let hero = UIImageView(image: UIImage(named: "lauching"))
        hero.contentMode = .scaleAspectFill
        hero.clipsToBounds = true
        view.addSubview(hero)
        hero.pin(to: view)

        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        view.addSubview(overlay)
        overlay.pin(to: view)

        let card = UIView()
        card.backgroundColor = .clear
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.25
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 3)
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(118)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(54)
        }

        let cardBackground = UIImageView(image: UIImage(named: "eula_bg"))
        cardBackground.contentMode = .scaleToFill
        cardBackground.isUserInteractionEnabled = false
        card.addSubview(cardBackground)
        cardBackground.snp.makeConstraints { $0.edges.equalToSuperview() }

        let heading = UILabel()
        heading.text = "EULA"
        heading.font = .systemFont(ofSize: 30, weight: .black)
        heading.textAlignment = .center
        let body = UITextView()
        body.text = """
        Welcome to Kavo! To create a positive, safe and standardized space for vintage fashion sharing, the following content is strictly prohibited on the app:
        1. Any content involving child harm, pornography or other materials detrimental to minors’ physical and mental health, including texts, images, videos or comments that insult, defame or improperly use minors’ portraits and information.
        2. False and harmful public information, including false content generated by AI or other means that disrupts public order, misleading guidance and false public opinion content.
        3. Violent content, cyber bullying, illegal acts or content that disrupts the network ecological environment. Specifically, it is forbidden to publish content that promotes pornography, illegal acts or disrupts the network ecological environment.
        """
        body.font = .systemFont(ofSize: 14, weight: .bold)
        body.textColor = .black
        body.backgroundColor = .clear
        body.isEditable = false
        body.showsVerticalScrollIndicator = false
        body.textContainerInset = .zero
        body.textContainer.lineFragmentPadding = 0
        let cancel = AuthBottomButton(title: "Cancel")
        let agree = AuthBottomButton(title: "Agree")
        agree.backgroundColor = AuthMetrics.orange
        agree.setTitleColor(.white, for: .normal)
        agree.addAction(UIAction { [weak self] _ in
            EULAConsentStore.accept()
            self?.navigationController?.setViewControllers([WelcomeViewController()], animated: true)
        }, for: .touchUpInside)
        cancel.addAction(UIAction { _ in
            exit(EXIT_SUCCESS)
        }, for: .touchUpInside)
        let actions = UIStackView(arrangedSubviews: [cancel, agree])
        actions.spacing = 24
        actions.distribution = .fillEqually
        card.addSubview(heading)
        card.addSubview(body)
        card.addSubview(actions)
        heading.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(23)
            make.centerX.equalToSuperview()
        }
        body.snp.makeConstraints { make in
            make.top.equalTo(heading.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(23)
            make.bottom.equalTo(actions.snp.top).offset(-14)
        }
        actions.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(25)
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(16)
            make.height.equalTo(70)
        }
        let legal = LegalLinksTextView()
        legal.onOpenLink = { [weak self] destination in
            self?.openLegalPage(destination: destination)
        }
        view.insertSubview(legal, belowSubview: overlay)
        legal.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(45)
            make.trailing.equalToSuperview().inset(25)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(4)
            make.height.equalTo(40)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func openLegalPage(destination: String) {
        let urlString = destination == "privacy"
            ? "https://sites.google.com/view/kavo-v/privacy"
            : "https://sites.google.com/view/kavo-v/users"
        guard let url = URL(string: urlString) else { return }
        let title = destination == "privacy" ? "Privacy Policy" : "Terms of Service"
        navigationController?.pushViewController(WebPageViewController(title: title, url: url), animated: true)
    }
}

private final class WelcomeBackgroundBlurView: UIView {
    private let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let gradientMask = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        addSubview(effectView)
        gradientMask.colors = [
            UIColor.black.withAlphaComponent(0.18).cgColor,
            UIColor.black.withAlphaComponent(0.32).cgColor,
            UIColor.black.withAlphaComponent(0.92).cgColor,
            UIColor.black.cgColor
        ]
        gradientMask.locations = [0, 0.42, 0.68, 1]
        gradientMask.startPoint = CGPoint(x: 0.5, y: 0)
        gradientMask.endPoint = CGPoint(x: 0.5, y: 1)
        effectView.layer.mask = gradientMask
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        effectView.frame = bounds
        gradientMask.frame = effectView.bounds
    }
}

final class WelcomeViewController: KavoViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = UIColor(hex: 0xF8EDD9)

        let background = UIImageView(image: UIImage(named: "bg"))
        background.contentMode = .scaleAspectFit
        background.clipsToBounds = false
        view.addSubview(background)
        background.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(33)
            make.height.equalTo(background.snp.width).multipliedBy(847.0 / 558.0)
        }

        let backgroundBlur = WelcomeBackgroundBlurView()
        view.addSubview(backgroundBlur)
        backgroundBlur.snp.makeConstraints { make in
            make.edges.equalTo(background)
        }

        let brand = UIImageView(image: UIImage(named: "font"))
        brand.contentMode = .scaleAspectFit
        view.addSubview(brand)
        brand.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(brand.snp.width).multipliedBy(294.0 / 1032.0)
            make.bottom.equalTo(view.snp.centerY).offset(-8)
        }

        let login = AuthBottomButton(title: "Login by email")
        let signup = AuthBottomButton(title: "I'm new")
        let legal = LegalConsentView()
        login.addAction(UIAction { [weak self, weak legal] _ in
            guard let self, legal?.isAccepted == true else {
                self?.showMessage(
                    "Agreement required",
                    message: "Please agree to the Terms of Service and Privacy Policy before continuing."
                )
                return
            }
            navigationController?.pushViewController(AuthFormViewController(mode: .signIn), animated: true)
        }, for: .touchUpInside)
        signup.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            AuthSessionStore.enterGuestMode()
            MockRepository.reloadSharedForCurrentAccount()
            guard let scene = view.window?.windowScene?.delegate as? SceneDelegate else { return }
            scene.window?.rootViewController = MainTabBarController()
        }, for: .touchUpInside)
        view.addSubview(login)
        view.addSubview(signup)
        login.snp.makeConstraints { make in
            make.top.equalTo(brand.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(34)
        }
        signup.snp.makeConstraints { make in
            make.top.equalTo(login.snp.bottom).offset(23)
            make.leading.trailing.equalTo(login)
        }

        let signupLink = UIButton(type: .system)
        let signupText = "Don't have an account? Sign up"
        let signupAttributedText = NSMutableAttributedString(
            string: signupText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: KavoColor.textPrimary
            ]
        )
        signupAttributedText.addAttributes(
            [
                .foregroundColor: AuthMetrics.orange,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ],
            range: (signupText as NSString).range(of: "Sign up")
        )
        signupLink.setAttributedTitle(signupAttributedText, for: .normal)
        signupLink.addAction(UIAction { [weak self] _ in self?.navigationController?.pushViewController(AuthFormViewController(mode: .signUp), animated: true) }, for: .touchUpInside)
        legal.onOpenLink = { [weak self] destination in
            self?.openLegalPage(destination: destination)
        }
        view.addSubview(signupLink)
        view.addSubview(legal)
        signupLink.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(legal.snp.top).offset(-32)
            make.top.greaterThanOrEqualTo(signup.snp.bottom).offset(16)
            make.height.equalTo(24)
        }
        legal.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(35)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(8)
            make.height.equalTo(40)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func openLegalPage(destination: String) {
        let urlString = destination == "privacy"
            ? "https://sites.google.com/view/kavo-v/privacy"
            : "https://sites.google.com/view/kavo-v/users"
        guard let url = URL(string: urlString) else { return }
        let title = destination == "privacy" ? "Privacy Policy" : "Terms of Service"
        navigationController?.pushViewController(WebPageViewController(title: title, url: url), animated: true)
    }
}

final class AuthFormViewController: KavoViewController {
    enum Mode { case signIn, signUp, reset }
    private let mode: Mode
    private let email = AuthField(title: "EMAIL", placeholder: "Enter Email Address")
    private let password = AuthField(title: "PASSWORD", placeholder: "Enter Password", secure: true, accessory: UIImage(systemName: "eye.slash.fill"))
    private let confirmation = AuthField(title: "PASSWORD", placeholder: "Please Enter The Password Again", secure: true, accessory: UIImage(systemName: "eye.fill"))
    private let content = UIView()

    init(mode: Mode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = AuthMetrics.warmBackground
        let back = AuthBackButton(action: UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) })
        let hello = UILabel()
        hello.text = "Hello"
        hello.font = .systemFont(ofSize: 53, weight: .black)
        hello.textColor = .black
        let welcome = UILabel()
        welcome.text = "Welcome to Kavo"
        welcome.font = .systemFont(ofSize: 22, weight: .regular)
        let arrow = UIImageView(image: UIImage(named: "right_arrow_long"))
        arrow.contentMode = .scaleAspectFit
        let tabs = makeTabs()
        let action = AuthBottomButton(title: mode == .signIn ? "Sign in" : mode == .signUp ? "Sign up" : "Save")
        action.addAction(UIAction { [weak self] _ in self?.submit() }, for: .touchUpInside)
        view.addSubview(back)
        view.addSubview(hello)
        view.addSubview(welcome)
        view.addSubview(arrow)
        view.addSubview(tabs)
        view.addSubview(content)
        view.addSubview(action)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
        }
        hello.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(26)
            make.top.equalToSuperview().offset(107)
        }
        welcome.snp.makeConstraints { make in
            make.leading.equalTo(hello)
            make.top.equalTo(hello.snp.bottom).offset(2)
        }
        arrow.snp.makeConstraints { make in
            make.leading.equalTo(welcome.snp.trailing).offset(14)
            make.trailing.equalToSuperview().inset(35)
            make.centerY.equalTo(welcome).offset(1)
            make.height.equalTo(7)
        }
        tabs.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AuthMetrics.pageInset)
            make.trailing.equalToSuperview().inset(AuthMetrics.pageInset)
            make.top.equalToSuperview().offset(218)
            make.height.equalTo(43)
        }
        content.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AuthMetrics.pageInset)
            make.trailing.equalToSuperview().inset(AuthMetrics.pageInset)
            make.top.equalTo(tabs.snp.bottom).offset(25)
        }
        action.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(12)
        }
        layoutFields()
    }

    private func makeTabs() -> UIView {
        let wrapper = UIView()
        let line = UIView()
        line.backgroundColor = UIColor(hex: 0xE3DDD5)
        wrapper.addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        let selected = UIView()
        selected.backgroundColor = AuthMetrics.orange
        wrapper.addSubview(selected)
        let first = UIButton(type: .system)
        let second = UIButton(type: .system)
        first.titleLabel?.font = .systemFont(ofSize: 15, weight: .black)
        second.titleLabel?.font = .systemFont(ofSize: 15, weight: .black)
        if mode == .reset {
            first.setTitle("FORGOT PASSWORD", for: .normal)
            first.setTitleColor(.black, for: .normal)
            first.isUserInteractionEnabled = false
            wrapper.addSubview(first)
            first.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            selected.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(2)
            }
        } else {
            first.setTitle("SIGN IN", for: .normal)
            second.setTitle("SIGN UP", for: .normal)
            first.addAction(UIAction { [weak self] _ in self?.navigate(to: .signIn) }, for: .touchUpInside)
            second.addAction(UIAction { [weak self] _ in self?.navigate(to: .signUp) }, for: .touchUpInside)
            let stack = UIStackView(arrangedSubviews: [first, second])
            stack.distribution = .fillEqually
            wrapper.addSubview(stack)
            stack.pin(to: wrapper)
            selected.snp.makeConstraints { make in
                make.width.equalToSuperview().multipliedBy(0.5)
                if mode == .signIn { make.leading.equalToSuperview() }
                else { make.leading.equalTo(wrapper.snp.centerX) }
                make.bottom.equalToSuperview()
                make.height.equalTo(2)
            }
            first.setTitleColor(mode == .signIn ? .black : UIColor(hex: 0x8C8983), for: .normal)
            second.setTitleColor(mode == .signUp ? .black : UIColor(hex: 0x8C8983), for: .normal)
            first.isUserInteractionEnabled = mode != .signIn
            second.isUserInteractionEnabled = mode != .signUp
        }
        return wrapper
    }

    private func navigate(to destination: Mode) {
        guard destination != mode else { return }
        let controller = AuthFormViewController(mode: destination)
        guard let navigationController else { return }
        var controllers = navigationController.viewControllers
        if controllers.last === self {
            controllers.removeLast()
        }
        controllers.append(controller)
        navigationController.setViewControllers(controllers, animated: false)
    }

    private func layoutFields() {
        let arranged: [UIView]
        if mode == .signIn {
            let forgot = UIButton(type: .system)
            forgot.setTitle("Forgot Password?", for: .normal)
            forgot.setTitleColor(AuthMetrics.orange, for: .normal)
            forgot.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            forgot.contentHorizontalAlignment = .leading
            forgot.addAction(UIAction { [weak self] _ in self?.navigationController?.pushViewController(AuthFormViewController(mode: .reset), animated: true) }, for: .touchUpInside)
            arranged = [email, password, forgot]
        } else {
            arranged = [email, password, confirmation]
        }
        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.spacing = mode == .signIn ? 19 : 18
        content.addSubview(stack)
        stack.pin(to: content)
        email.field.keyboardType = .emailAddress
        if mode == .signIn, let forgot = arranged.last {
            forgot.snp.makeConstraints { $0.height.equalTo(30) }
        }
    }

    private func submit() {
        let emailValue = email.field.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let passwordValue = password.field.text ?? ""
        guard emailValue.contains("@") else {
            showMessage("Check email", message: "Enter a valid email address.")
            return
        }
        guard passwordValue.count >= 8 else {
            showMessage("Check password", message: "Use at least 8 characters.")
            return
        }

        switch mode {
        case .reset:
            guard passwordValue == confirmation.field.text else {
                showMessage("Passwords don't match")
                return
            }
            guard AuthSessionStore.resetPassword(email: emailValue, newPassword: passwordValue) else {
                showMessage("Account not found", message: "No local account exists for this email address.")
                return
            }
            showMessage("Password updated", message: "Sign in with your new password.")
        case .signUp:
            guard passwordValue == confirmation.field.text else {
                showMessage("Passwords don't match")
                return
            }
            guard AuthSessionStore.register(email: emailValue, password: passwordValue) else {
                showMessage("Account already exists", message: "Sign in with this email address instead.")
                return
            }
            MockRepository.reloadSharedForCurrentAccount()
            navigationController?.pushViewController(ProfileSetupViewController(), animated: true)
        case .signIn:
            guard AuthSessionStore.signIn(email: emailValue, password: passwordValue) else {
                showMessage("Unable to sign in", message: "Incorrect email or password.")
                return
            }
            MockRepository.reloadSharedForCurrentAccount()
            guard let scene = view.window?.windowScene?.delegate as? SceneDelegate else { return }
            scene.window?.rootViewController = MainTabBarController()
        }
    }
}

private final class BirthdayPickerViewController: UIViewController {
    var onDone: ((Date) -> Void)?
    private let initialDate: Date
    private let picker = UIDatePicker()

    init(initialDate: Date) {
        self.initialDate = initialDate
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AuthMetrics.warmBackground
        let title = UILabel()
        title.text = "Birthday"
        title.font = .systemFont(ofSize: 20, weight: .bold)
        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        let done = UIButton(type: .system)
        done.setTitle("Done", for: .normal)
        done.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        done.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let selectedDate = picker.date
            dismiss(animated: true) { self.onDone?(selectedDate) }
        }, for: .touchUpInside)
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.maximumDate = Date()
        picker.date = min(initialDate, Date())
        [title, cancel, done, picker].forEach(view.addSubview)
        title.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
        }
        cancel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalTo(title)
            make.size.equalTo(CGSize(width: 70, height: 44))
        }
        done.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalTo(title)
            make.size.equalTo(CGSize(width: 70, height: 44))
        }
        picker.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }
        if let sheetPresentationController {
            sheetPresentationController.detents = [.medium()]
            sheetPresentationController.prefersGrabberVisible = true
        }
    }
}

final class ProfileSetupViewController: KavoViewController, CLLocationManagerDelegate {
    enum Gender { case male, female }
    private let name = AuthField(title: "NAME", placeholder: "Please Enter")
    private let birthday = AuthField(title: "BIRTHDAY", placeholder: "2003-01-01", accessory: UIImage(systemName: "chevron.right"))
    private let location = AuthField(title: "LOCATION", placeholder: "LB", accessory: UIImage(systemName: "chevron.right"))
    private let avatar = UIImageView(image: kavoDefaultAvatarImage())
    private let maleButton = UIButton(type: .system)
    private let femaleButton = UIButton(type: .system)
    private let imagePicker = KavoImagePickerCoordinator()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var gender: Gender
    private var selectedBirthday = Date(timeIntervalSince1970: 1_041_379_200)
    private var selectedAvatarData: Data?

    init(gender: Gender = .male) {
        self.gender = gender
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = AuthMetrics.warmBackground
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 40
        avatar.layer.cornerCurve = .continuous
        avatar.clipsToBounds = true
        avatar.isUserInteractionEnabled = true
        avatar.accessibilityLabel = "Profile photo"
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showPhotoOptions)))
        let camera = UIButton(type: .system)
        camera.setImage(UIImage(named: "carmera")?.withRenderingMode(.alwaysOriginal), for: .normal)
        camera.imageView?.contentMode = .scaleAspectFit
        camera.accessibilityLabel = "Change profile photo"
        camera.addAction(UIAction { [weak self] _ in self?.showPhotoOptions() }, for: .touchUpInside)
        imagePicker.onImagesPicked = { [weak self] images in
            guard let self, let image = images.first else { return }
            avatar.image = image
            selectedAvatarData = image.jpegData(compressionQuality: 0.82)
        }
        birthday.field.isUserInteractionEnabled = false
        birthday.field.text = "2003-01-01"
        birthday.isUserInteractionEnabled = true
        birthday.accessibilityLabel = "Birthday"
        birthday.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showBirthdayPicker)))
        location.field.isUserInteractionEnabled = false
        location.isUserInteractionEnabled = true
        location.accessibilityLabel = "Location"
        location.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(requestLocation)))
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        let genderLabel = UILabel()
        genderLabel.text = "GENDER"
        genderLabel.font = .systemFont(ofSize: 16, weight: .bold)
        genderLabel.textColor = AuthMetrics.orange
        configureChoiceButton(maleButton)
        configureChoiceButton(femaleButton)
        maleButton.addAction(UIAction { [weak self] _ in self?.selectGender(.male) }, for: .touchUpInside)
        femaleButton.addAction(UIAction { [weak self] _ in self?.selectGender(.female) }, for: .touchUpInside)
        applyGenderStyles()
        let choices = UIStackView(arrangedSubviews: [maleButton, femaleButton])
        choices.spacing = 18
        choices.distribution = .fillEqually
        let back = AuthBackButton(action: UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        let save = AuthBottomButton(title: "Save")
        save.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let value = name.field.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard value.count >= 2 else {
                showMessage("Enter a display name")
                return
            }
            repository.updateProfile(
                name: value,
                bio: repository.currentUser.bio,
                birthday: birthday.field.text ?? "",
                location: location.field.text ?? "",
                gender: gender == .male ? "male" : "female",
                avatarData: selectedAvatarData
            )
            AuthSessionStore.completeRegistration()
            repository.reloadAccountState()
            if let scene = view.window?.windowScene?.delegate as? SceneDelegate { scene.window?.rootViewController = MainTabBarController() }
        }, for: .touchUpInside)
        [avatar, camera, back, name, birthday, location, genderLabel, choices, save].forEach(view.addSubview)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(2)
        }
        avatar.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(64)
            make.centerX.equalToSuperview()
            make.size.equalTo(138)
        }
        camera.snp.makeConstraints { make in
            make.trailing.bottom.equalTo(avatar).offset(7)
            make.size.equalTo(45)
        }
        name.snp.makeConstraints { make in
            make.top.equalTo(avatar.snp.bottom).offset(25)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        birthday.snp.makeConstraints { make in
            make.top.equalTo(name.snp.bottom).offset(18)
            make.leading.trailing.equalTo(name)
        }
        location.snp.makeConstraints { make in
            make.top.equalTo(birthday.snp.bottom).offset(18)
            make.leading.trailing.equalTo(name)
        }
        genderLabel.snp.makeConstraints { make in
            make.top.equalTo(location.snp.bottom).offset(18)
            make.leading.equalTo(name)
        }
        choices.snp.makeConstraints { make in
            make.top.equalTo(genderLabel.snp.bottom).offset(13)
            make.leading.trailing.equalTo(name)
            make.height.equalTo(61)
        }
        save.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(12)
        }
    }

    private func configureChoiceButton(_ button: UIButton) {
        button.layer.cornerRadius = 12
        button.layer.shadowOffset = CGSize(width: 3, height: 3)
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 0
    }

    private func selectGender(_ value: Gender) {
        gender = value
        applyGenderStyles()
    }

    private func applyGenderStyles() {
        applyStyle(
            to: maleButton,
            selected: gender == .male,
            selectedColor: UIColor(hex: 0x73AEDC),
            selectedBackground: UIColor(hex: 0xD7EDFC)
        )
        applyStyle(
            to: femaleButton,
            selected: gender == .female,
            selectedColor: UIColor(hex: 0xD96B91),
            selectedBackground: UIColor(hex: 0xF9DCE6)
        )
    }

    private func applyStyle(to button: UIButton, selected: Bool, selectedColor: UIColor, selectedBackground: UIColor) {
        let color = selected ? selectedColor : UIColor(hex: 0xD8D1C5)
        let symbol = button === maleButton ? "♂" : "♀"
        let title = button === maleButton ? "Man" : "Madam"
        let attributedTitle = NSMutableAttributedString(
            string: "\(symbol) ",
            attributes: [
                .font: UIFont.systemFont(ofSize: 25, weight: .bold),
                .foregroundColor: color,
                .baselineOffset: -1
            ]
        )
        attributedTitle.append(NSAttributedString(
            string: title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: color
            ]
        ))
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.backgroundColor = selected ? selectedBackground : UIColor(hex: 0xFFFCF5)
        button.layer.borderWidth = selected ? 0 : 1
        button.layer.borderColor = UIColor(hex: 0xE6E0D7).cgColor
        button.layer.shadowColor = (selected ? UIColor.black : UIColor(hex: 0xE6E0D7)).cgColor
    }

    @objc private func showPhotoOptions() {
        imagePicker.presentSourceSheet(from: self, sourceView: avatar)
    }

    @objc private func showBirthdayPicker() {
        let controller = BirthdayPickerViewController(initialDate: selectedBirthday)
        controller.onDone = { [weak self] date in
            guard let self else { return }
            selectedBirthday = date
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            birthday.field.text = formatter.string(from: date)
        }
        present(controller, animated: true)
    }

    @objc private func requestLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied, .restricted:
            showMessage("Location unavailable", message: "Enable Location access for Kavo in Settings.")
        @unknown default:
            showMessage("Location unavailable")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last else { return }
        geocoder.reverseGeocodeLocation(coordinate) { [weak self] placemarks, _ in
            guard let self, let placemark = placemarks?.first else {
                self?.showMessage("Unable to resolve location")
                return
            }
            let components = [placemark.locality, placemark.administrativeArea, placemark.country]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
            location.field.text = components.prefix(2).joined(separator: ", ")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showMessage("Unable to get location", message: error.localizedDescription)
    }
}
