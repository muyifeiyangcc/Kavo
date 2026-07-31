import UIKit
import SnapKit
import WebKit

final class WebPageViewController: KavoViewController {
    private let pageTitle: String
    private let pageURL: URL
    private let webView = WKWebView()

    init(title: String, url: URL) {
        pageTitle = title
        pageURL = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = pageTitle
        webView.backgroundColor = KavoColor.canvas
        view.addSubview(webView)
        webView.snp.makeConstraints { $0.edges.equalToSuperview() }
        webView.load(URLRequest(url: pageURL))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

final class SettingsViewController: KavoViewController, UITableViewDataSource, UITableViewDelegate {
    enum InitialAction { case none, deleteAccount, logout }
    private let initialAction: InitialAction
    private let rows = ["Wallet", "Blocklist", "Privacy Policy", "Terms of Service", "Delete Account", "Log out"]
    private let table = UITableView(frame: .zero, style: .plain)
    init(initialAction: InitialAction = .none) {
        self.initialAction = initialAction
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        table.backgroundColor = KavoColor.canvas
        table.separatorStyle = .none
        table.rowHeight = 54
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Setting")
        view.addSubview(table)
        table.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if initialAction == .deleteAccount { showDelete() }
        if initialAction == .logout { showLogout() }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Setting", for: indexPath)
        var config = UIListContentConfiguration.cell()
        config.text = rows[indexPath.row]
        config.textProperties.font = KavoFont.headline
        cell.contentConfiguration = config
        cell.backgroundColor = KavoColor.canvas
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0: navigationController?.pushViewController(RechargeViewController(), animated: true)
        case 1: navigationController?.pushViewController(RelationshipListViewController(mode: .blocked), animated: true)
        case 2, 3:
            guard let url = URL(string: "https://www.baidu.com") else { return }
            navigationController?.pushViewController(
                WebPageViewController(title: rows[indexPath.row], url: url),
                animated: true
            )
        case 4: showDelete()
        case 5: showLogout()
        default: break
        }
    }
    private func showDelete() {
        present(KavoDecisionModalViewController(kind: .deleteAccount, primaryTitle: "Sure") { [weak self] in
            guard let self else { return }
            guard let scene = view.window?.windowScene?.delegate as? SceneDelegate else { return }
            do {
                try MockRepository.shared.deleteCurrentAccountData()
                AuthSessionStore.deleteAccount()
                MockRepository.reloadSharedForCurrentAccount()
                scene.window?.rootViewController = UINavigationController(rootViewController: WelcomeViewController())
            } catch {
                showMessage(
                    "Unable to Delete Account",
                    message: "Your local account data could not be completely removed. Please try again."
                )
            }
        }, animated: true)
    }
    private func showLogout() {
        present(KavoDecisionModalViewController(kind: .logout, primaryTitle: "Confirm") { [weak self] in
            guard let scene = self?.view.window?.windowScene?.delegate as? SceneDelegate else { return }
            AuthSessionStore.signOut()
            scene.window?.rootViewController = UINavigationController(rootViewController: WelcomeViewController())
        }, animated: true)
    }
}

private final class RelationshipCell: UITableViewCell {
    static let reuse = "RelationshipCell"
    let action = UIButton(type: .custom)
    private let avatar = UIImageView(image: kavoDefaultAvatarImage())
    private let name = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = KavoColor.canvas
        contentView.backgroundColor = KavoColor.canvas
        selectionStyle = .none
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 16
        avatar.layer.cornerCurve = .continuous
        name.font = .systemFont(ofSize: 24, weight: .black)
        name.textColor = KavoColor.textPrimary
        contentView.addSubview(avatar)
        contentView.addSubview(name)
        contentView.addSubview(action)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(23)
            make.centerY.equalToSuperview()
            make.size.equalTo(54)
        }
        name.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(14)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(action.snp.leading).offset(-10)
        }
        action.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(23)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
        }
    }

    required init?(coder: NSCoder) { nil }

    func apply(user: User, mode: RelationshipListViewController.Mode, avatarImage: UIImage?) {
        avatar.image = avatarImage ?? kavoDefaultAvatarImage()
        name.text = user.name
        let followBack = mode == .followers && user.relationship == .followedBy
        let assetName = followBack ? "add" : "abstract"
        action.setImage(UIImage(named: assetName)?.withRenderingMode(.alwaysOriginal), for: .normal)
        action.accessibilityLabel = followBack ? "Follow" : (mode == .blocked ? "Unblock" : "Unfollow")
    }
}

final class RelationshipListViewController: KavoViewController, UITableViewDataSource, UITableViewDelegate {
    enum Mode: String { case following = "Following", followers = "Followers", blocked = "Blocklist" }
    private let mode: Mode
    private let table = UITableView(frame: .zero, style: .plain)
    init(mode: Mode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }
    private var entries: [User] {
        switch mode {
        case .following: return repository.visibleUsers.filter { $0.relationship == .following || $0.relationship == .mutual }
        case .followers: return repository.visibleUsers.filter { $0.relationship == .followedBy || $0.relationship == .mutual }
        case .blocked: return repository.users.filter { $0.relationship == .blocked }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = mode.rawValue
        table.backgroundColor = KavoColor.canvas
        table.separatorStyle = .none
        table.rowHeight = 84
        table.contentInsetAdjustmentBehavior = .never
        table.dataSource = self
        table.delegate = self
        table.register(RelationshipCell.self, forCellReuseIdentifier: RelationshipCell.reuse)
        view.addSubview(table)
        table.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(18)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: KavoColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 28, weight: .bold)
        ]
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: KavoColor.textPrimary,
            .font: KavoFont.title3
        ]
    }

    override func repositoryDidChange() { table.reloadData() }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        entries.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RelationshipCell.reuse, for: indexPath) as! RelationshipCell
        let user = entries[indexPath.row]
        let avatarImage = user.avatarName.flatMap(UIImage.init(named:)) ?? kavoDefaultAvatarImage()
        cell.apply(user: user, mode: mode, avatarImage: avatarImage)
        cell.action.removeTarget(nil, action: nil, for: .allEvents)
        cell.action.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            if mode == .blocked { repository.unblock(userID: user.id) }
            else { _ = repository.toggleFollow(userID: user.id) }
        }, for: .touchUpInside)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard mode != .blocked else { return }
        navigationController?.pushViewController(ProfileViewController(userID: entries[indexPath.row].id), animated: true)
    }
}

private final class ReportReasonCell: UITableViewCell {
    static let reuseIdentifier = "ReportReasonCell"
    private let card = UIView()
    private let reasonLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = KavoColor.canvas
        contentView.backgroundColor = KavoColor.canvas
        selectionStyle = .none
        card.layer.cornerRadius = 15
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.black.cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 0
        reasonLabel.font = .systemFont(ofSize: 17, weight: .bold)
        card.addSubview(reasonLabel)
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(53)
        }
        reasonLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(17)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { nil }

    func apply(reason: String, selected: Bool) {
        reasonLabel.text = reason
        reasonLabel.textColor = selected ? .white : KavoColor.textPrimary
        card.backgroundColor = selected ? KavoColor.primary : .white
    }
}

final class ReportViewController: KavoViewController, UITableViewDataSource, UITableViewDelegate {
    private let reasons = ["Politically sensitive", "Bloody violence", "Frequent harassment", "Infringement of rights", "Pornographic and vulgar", "Discrimination", "Others"]
    private var selection = 0
    private let table = UITableView(frame: .zero, style: .plain)
    private let save = UIButton(type: .custom)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Report"
        table.backgroundColor = KavoColor.canvas
        table.separatorStyle = .none
        table.rowHeight = 70
        table.isScrollEnabled = false
        table.dataSource = self
        table.delegate = self
        table.register(ReportReasonCell.self, forCellReuseIdentifier: ReportReasonCell.reuseIdentifier)
        save.setTitle("Save", for: .normal)
        save.setTitleColor(.black, for: .normal)
        save.titleLabel?.font = .systemFont(ofSize: 22, weight: .bold)
        save.backgroundColor = .white
        save.layer.cornerRadius = 18
        save.layer.cornerCurve = .continuous
        save.layer.borderWidth = 1
        save.layer.borderColor = UIColor.black.cgColor
        save.layer.shadowColor = UIColor.black.cgColor
        save.layer.shadowOffset = CGSize(width: 0, height: 4)
        save.layer.shadowOpacity = 1
        save.layer.shadowRadius = 0
        save.addAction(UIAction { [weak self] _ in
            self?.showMessage("Report submitted")
        }, for: .touchUpInside)
        view.addSubview(table)
        view.addSubview(save)
        table.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(25)
            make.leading.equalToSuperview().offset(28)
            make.trailing.equalToSuperview().inset(25)
            make.height.equalTo(490)
        }
        save.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(4)
            make.height.equalTo(68)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: KavoColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 28, weight: .bold)
        ]
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: KavoColor.textPrimary,
            .font: KavoFont.title3
        ]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { reasons.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ReportReasonCell.reuseIdentifier,
            for: indexPath
        ) as! ReportReasonCell
        cell.apply(reason: reasons[indexPath.row], selected: indexPath.row == selection)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selection = indexPath.row
        table.reloadData()
    }
}

final class KavoDecisionModalViewController: UIViewController {
    enum Kind {
        case insufficientCoins, loginRequired, deleteAccount, connect, logout
        var title: String {
            switch self {
            case .insufficientCoins: return "Insufficient Coins"
            case .loginRequired: return "Login Required"
            case .deleteAccount: return "Delete Account"
            case .connect: return "Connect to Chat"
            case .logout: return "Log Out"
            }
        }
        var message: String {
            switch self {
            case .insufficientCoins: return "Unfortunately, your account balance is insufficient. Please go to recharge."
            case .loginRequired: return "To ensure the normal operation of the function, please log in to your account first."
            case .deleteAccount: return "Are you sure you want to delete this account? All data will be cleared after deletion and cannot be recovered."
            case .connect: return "You can only send messages once you follow each other."
            case .logout: return "Are you sure you want to log out of your account?"
            }
        }
    }
    private let kind: Kind
    private let primaryTitle: String
    private let action: () -> Void
    init(kind: Kind, primaryTitle: String, action: @escaping () -> Void) {
        self.kind = kind
        self.primaryTitle = primaryTitle
        self.action = action
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
        let title = UILabel()
        title.text = kind.title
        title.font = KavoFont.title2
        title.textAlignment = .center
        title.numberOfLines = 2
        let detail = UILabel()
        detail.text = kind.message
        detail.font = KavoFont.body
        detail.textAlignment = .center
        detail.numberOfLines = 0
        let cancel = KavoButton("Cancel", style: .outline)
        let primary = KavoButton(primaryTitle)
        cancel.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        primary.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true) { self?.action() }
        }, for: .touchUpInside)
        let buttons = UIStackView(arrangedSubviews: [cancel, primary])
        buttons.spacing = 14
        buttons.distribution = .fillEqually
        let stack = UIStackView(arrangedSubviews: [title, detail, buttons])
        stack.axis = .vertical
        stack.spacing = 18
        view.addSubview(card)
        card.addSubview(stack)
        card.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-68)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.greaterThanOrEqualTo(233)
        }
        stack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(42)
            $0.leading.trailing.equalToSuperview().inset(28)
            $0.bottom.equalToSuperview().inset(28)
        }
    }
}

final class DecisionModalHostViewController: KavoViewController {
    private let kind: KavoDecisionModalViewController.Kind
    init(kind: KavoDecisionModalViewController.Kind) {
        self.kind = kind
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let title = kind == .insufficientCoins ? "Recharge" : kind == .logout ? "Confirm" : "Sure"
        present(KavoDecisionModalViewController(kind: kind, primaryTitle: title) {}, animated: false)
    }
}

enum UIStateRouter {
    static let namesByID: [Int: String] = [
        1: "launch", 2: "eula", 3: "welcome", 4: "signIn", 5: "signUp", 6: "reset",
        7: "profileMale", 8: "profileFemale", 9: "homeLatest", 10: "homeWornFor",
        11: "exploreLocked", 12: "exploreUnlocked", 13: "exploreLiked",
        14: "publishEmpty", 15: "itemNew", 16: "itemMultiple", 17: "publishLinked",
        18: "chatList", 19: "interaction", 20: "chatTextImage", 21: "chatMore",
        22: "otherProfile", 23: "chatVoice", 24: "holdToTalk", 25: "releaseToSend",
        26: "me", 27: "editProfile", 28: "settings", 29: "report",
        30: "following", 31: "followers", 32: "blocklist", 33: "recharge",
        34: "insufficient", 35: "loginRequired", 36: "deleteAccount",
        37: "connectChat", 38: "logOut", 39: "comments", 40: "itemDetail",
        41: "postUnlocked", 42: "postLocked", 43: "unlockConfirm"
    ]

    static func root(for state: String) -> UIViewController? {
        if state == "stateGallery" {
            return UINavigationController(rootViewController: StateGalleryViewController())
        }
        guard let destination = destination(for: state) else { return nil }
        if destination is MainTabBarController ||
            destination is LaunchViewController ||
            destination is UnlockPromptViewController {
            return destination
        }
        return UINavigationController(rootViewController: destination)
    }

    static func destination(for state: String) -> UIViewController? {
        let repository = MockRepository.shared
        let firstPost = repository.posts.first
        let unlockedPost = repository.posts.first(where: \.isUnlocked)
        let mutualUser = repository.users.first(where: { $0.relationship == .mutual })
        let connectUser = repository.users.first(where: { $0.relationship != .mutual })

        switch state {
        case "launch":
            return LaunchViewController()
        case "eula":
            return EULAViewController()
        case "welcome":
            return WelcomeViewController()
        case "signIn":
            return AuthFormViewController(mode: .signIn)
        case "signUp":
            return AuthFormViewController(mode: .signUp)
        case "reset":
            return AuthFormViewController(mode: .reset)
        case "profileMale":
            return ProfileSetupViewController(gender: .male)
        case "profileFemale":
            return ProfileSetupViewController(gender: .female)
        case "homeLatest":
            return MainTabBarController(initialTab: 0, feedSegment: 0)
        case "homeWornFor":
            return MainTabBarController(initialTab: 0, feedSegment: 2)
        case "exploreLocked":
            return MainTabBarController(initialTab: 1, feedSegment: 0)
        case "exploreUnlocked":
            let launchedDirectly = launchState == "exploreUnlocked"
            return MainTabBarController(initialTab: 1, feedSegment: launchedDirectly ? 0 : 1)
        case "exploreLiked":
            if let firstPost, !firstPost.isLiked { _ = repository.toggleLike(postID: firstPost.id) }
            return MainTabBarController(initialTab: 1, feedSegment: 0)
        case "publishEmpty":
            return PublishViewController(draft: PublishDraft())
        case "itemNew":
            return ItemEditorViewController(session: PublishSession())
        case "itemMultiple":
            let session = PublishSession()
            session.draft.itemIDs = Array(repository.items.prefix(2).map(\.id))
            return ItemEditorViewController(session: session)
        case "publishLinked":
            return PublishViewController(draft: linkedDraft(repository: repository))
        case "chatList":
            return MessagesViewController(initialState: .chatList)
        case "interaction":
            return MessagesViewController(initialState: .interaction)
        case "chatTextImage":
            return mutualUser.map { ChatViewController(userID: $0.id, displayState: .normal) }
        case "chatMore":
            return mutualUser.map { ChatViewController(userID: $0.id, displayState: .moreMenu) }
        case "otherProfile":
            return mutualUser.map { ProfileViewController(userID: $0.id) }
        case "chatVoice":
            return mutualUser.map { ChatViewController(userID: $0.id, displayState: .voiceBubble) }
        case "holdToTalk":
            return mutualUser.map { ChatViewController(userID: $0.id, displayState: .holdToTalk) }
        case "releaseToSend":
            return mutualUser.map { ChatViewController(userID: $0.id, displayState: .releaseToSend) }
        case "me":
            return ProfileViewController(userID: repository.currentUser.id)
        case "editProfile":
            return EditProfileViewController()
        case "settings":
            return SettingsViewController()
        case "report":
            return ReportViewController()
        case "following":
            return RelationshipListViewController(mode: .following)
        case "followers":
            return RelationshipListViewController(mode: .followers)
        case "blocklist":
            if let user = connectUser, user.relationship != .blocked { repository.block(userID: user.id) }
            return RelationshipListViewController(mode: .blocked)
        case "recharge":
            return RechargeViewController()
        case "insufficient":
            return DecisionModalHostViewController(kind: .insufficientCoins)
        case "loginRequired":
            return DecisionModalHostViewController(kind: .loginRequired)
        case "deleteAccount":
            return SettingsViewController(initialAction: .deleteAccount)
        case "connectChat":
            return connectUser.map { ChatViewController(userID: $0.id, displayState: .connect) }
        case "logOut":
            return SettingsViewController(initialAction: .logout)
        case "comments":
            return firstPost.map { CommentsViewController(postID: $0.id) }
        case "itemDetail":
            return firstPost.map { ItemDetailViewController(itemIDs: $0.itemIDs) }
        case "postUnlocked":
            guard let post = unlockedPost ?? repository.posts.last else { return nil }
            return PostDetailViewController(postID: post.id)
        case "postLocked":
            return firstPost.map { PostDetailViewController(postID: $0.id) }
        case "unlockConfirm":
            guard let firstPost else { return nil }
            let prompt = UnlockPromptViewController(price: firstPost.unlockPrice)
            prompt.onConfirm = { try? repository.unlock(postID: firstPost.id) }
            return prompt
        default:
            return nil
        }
    }

    private static var launchState: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-uiState"),
              arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    private static func linkedDraft(repository: MockRepository) -> PublishDraft {
        var draft = PublishDraft()
        draft.photoCount = 2
        draft.yearsWorn = 3
        draft.title = "The Wardrobe Staple That Never Fades"
        draft.body = "Denim has always been one of the most effortless pieces."
        draft.itemIDs = Array(repository.items.prefix(2).map(\.id))
        draft.category = "Denim"
        return draft
    }
}

final class StateGalleryViewController: KavoViewController, UITableViewDataSource, UITableViewDelegate {
    struct State { let id: Int; let name: String; let detail: String }
    private let states: [State] = [
        .init(id: 1, name: "Brand Launch", detail: "0.8s bootstrap state"), .init(id: 2, name: "EULA", detail: "Scrollable agreement card"),
        .init(id: 3, name: "Welcome", detail: "Login / Sign up"), .init(id: 4, name: "Sign In", detail: "Validation and submission"),
        .init(id: 5, name: "Sign Up", detail: "Password confirmation"), .init(id: 6, name: "Forgot Password", detail: "Reset-link state"),
        .init(id: 7, name: "Profile · Male", detail: "Selected gender"), .init(id: 8, name: "Profile · Female", detail: "Selected gender"),
        .init(id: 9, name: "Home · Latest", detail: "Grid + refresh"), .init(id: 10, name: "Home · Worn For", detail: "Year filter"),
        .init(id: 11, name: "Explore · Locked", detail: "300 coin CTA"), .init(id: 12, name: "Explore · Unlocked", detail: "Item summaries"),
        .init(id: 13, name: "Explore · Liked", detail: "Optimistic like"), .init(id: 14, name: "Publish · Empty", detail: "Field validation"),
        .init(id: 15, name: "Item Editor · New", detail: "Create item"), .init(id: 16, name: "Item Editor · Multiple", detail: "Edit and reorder"),
        .init(id: 17, name: "Publish · Linked Items", detail: "1–10 relationships"), .init(id: 18, name: "Messages · Chat List", detail: "Last-message order"),
        .init(id: 19, name: "Messages · Interaction", detail: "Like/comment/follow"), .init(id: 20, name: "Chat · Text/Image", detail: "Send states"),
        .init(id: 21, name: "Chat · More Menu", detail: "Report/block"), .init(id: 22, name: "Other Profile", detail: "Relationship actions"),
        .init(id: 23, name: "Chat · Voice", detail: "Voice bubble"), .init(id: 24, name: "Chat · Hold to Talk", detail: "Idle recording"),
        .init(id: 25, name: "Chat · Release to Send", detail: "Recording active"), .init(id: 26, name: "Me", detail: "Wallet and shortcuts"),
        .init(id: 27, name: "Edit Profile", detail: "Shared user update"), .init(id: 28, name: "Settings", detail: "Account controls"),
        .init(id: 29, name: "Report", detail: "Single reason"), .init(id: 30, name: "Following", detail: "Remove + Undo contract"),
        .init(id: 31, name: "Followers", detail: "Follow back"), .init(id: 32, name: "Blocklist", detail: "Unblock confirmation"),
        .init(id: 33, name: "Recharge", detail: "Mock StoreKit tiers"), .init(id: 34, name: "Insufficient Coins", detail: "Recharge context"),
        .init(id: 35, name: "Login Required", detail: "Deferred action"), .init(id: 36, name: "Delete Account", detail: "Destructive confirm"),
        .init(id: 37, name: "Connect to Chat", detail: "Relationship-aware CTA"), .init(id: 38, name: "Log Out", detail: "Confirmation"),
        .init(id: 39, name: "Comments", detail: "Insert and refresh"), .init(id: 40, name: "Item Detail", detail: "Read-only sheet"),
        .init(id: 41, name: "Post · Unlocked", detail: "Item labels visible"), .init(id: 42, name: "Post · Locked", detail: "No item leakage"),
        .init(id: 43, name: "Unlock Confirmation", detail: "Idempotent charge"), .init(id: 44, name: "Loading", detail: "System activity state"),
        .init(id: 45, name: "Empty", detail: "Single recovery action"), .init(id: 46, name: "Error / Offline", detail: "Retry preserving cache"),
        .init(id: 47, name: "Permission Denied", detail: "Open Settings"), .init(id: 48, name: "Submitting", detail: "Disabled duplicate action")
    ]
    private let table = UITableView(frame: .zero, style: .plain)
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UI State Gallery"
        table.backgroundColor = KavoColor.canvas
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "State")
        view.addSubview(table)
        table.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { states.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let state = states[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "State", for: indexPath)
        var config = UIListContentConfiguration.subtitleCell()
        config.text = String(format: "%02d · %@", state.id, state.name)
        config.secondaryText = state.detail
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = states[indexPath.row].id
        let root: UIViewController?
        if let stateName = UIStateRouter.namesByID[id] {
            root = UIStateRouter.root(for: stateName)
        } else {
            root = StateDemoViewController(
                symbol: "square.grid.3x3",
                titleText: states[indexPath.row].name,
                detail: states[indexPath.row].detail
            )
        }
        guard let root else { return }
        root.modalPresentationStyle = .fullScreen
        present(root, animated: true)
    }
}

final class StateDemoViewController: KavoViewController {
    private let symbol: String
    private let titleText: String
    private let detail: String
    init(symbol: String, titleText: String, detail: String) {
        self.symbol = symbol
        self.titleText = titleText
        self.detail = detail
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = titleText
        let state = KavoStateView(symbol: symbol, title: titleText, detail: detail)
        view.addSubview(state)
        state.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }
    }
}
