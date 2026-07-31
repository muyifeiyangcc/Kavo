import UIKit
import SnapKit
import AVFoundation

private let videoFirstFrameCache = NSCache<NSURL, UIImage>()

func kavoVideoFirstFrame(url: URL) -> UIImage? {
    let key = url as NSURL
    if let cached = videoFirstFrameCache.object(forKey: key) {
        return cached
    }
    let asset = AVURLAsset(url: url)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: 1_200, height: 1_200)
    guard let cgImage = try? generator.copyCGImage(
        at: CMTime(seconds: 0.1, preferredTimescale: 600),
        actualTime: nil
    ) else {
        return nil
    }
    let image = UIImage(cgImage: cgImage)
    videoFirstFrameCache.setObject(image, forKey: key)
    return image
}

private func repositoryAvatarImage(userID: UUID, repository: MockRepository) -> UIImage {
    if userID == repository.currentUser.id,
       let data = repository.currentUserAvatarData,
       let image = UIImage(data: data) {
        return image
    }
    if let name = repository.user(id: userID)?.avatarName,
       let image = UIImage(named: name) {
        return image
    }
    return kavoDefaultAvatarImage()
}

private func postPlaceholderImage(isVideo: Bool = false) -> UIImage? {
    UIImage(
        systemName: isVideo ? "play.rectangle.fill" : "photo.fill",
        withConfiguration: UIImage.SymbolConfiguration(pointSize: 54, weight: .regular)
    )
}

final class MainTabBarController: UITabBarController, UINavigationControllerDelegate {
    private let floatingBar = UIView()
    private let floatingButtonRow = UIStackView()
    private var navButtons: [UIButton] = []
    private var floatingBarBottomConstraint: Constraint!
    private var appliedWindowBottomInset: CGFloat = -1
    private let initialTab: Int
    private let feedSegment: Int

    init(initialTab: Int = 0, feedSegment: Int = 0) {
        self.initialTab = initialTab
        self.feedSegment = feedSegment
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        hideSystemTabBar()
        let home = nav(FeedViewController(mode: .home, initialSegment: initialTab == 0 ? feedSegment : 0), title: "Home", symbol: "house")
        let explore = nav(FeedViewController(mode: .explore, initialSegment: initialTab == 1 ? feedSegment : 0), title: "Explore", symbol: "safari")
        let messages = nav(MessagesViewController(), title: "Messages", symbol: "bubble.left.and.bubble.right")
        let me = nav(ProfileViewController(userID: MockRepository.shared.currentUser.id), title: "Me", symbol: "person")
        viewControllers = [home, explore, messages, me]
        selectedIndex = min(initialTab, 3)
        hideSystemTabBar()
        setupFloatingBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideSystemTabBar()
        updateFloatingButtonSelection()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hideSystemTabBar()
        updateFloatingBarBottomInset()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateFloatingBarBottomInset()
    }

    private func hideSystemTabBar() {
        tabBar.layer.removeAllAnimations()
        tabBar.isHidden = true
        tabBar.isUserInteractionEnabled = false
        tabBar.alpha = 0
        tabBar.removeFromSuperview()
    }

    private func nav(_ root: UIViewController, title: String, symbol: String) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)
        nav.delegate = self
        nav.navigationBar.prefersLargeTitles = false
        nav.navigationBar.tintColor = KavoColor.textPrimary
        nav.navigationBar.titleTextAttributes = [.foregroundColor: KavoColor.textPrimary, .font: KavoFont.title3]
        return nav
    }

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        let isRootPage = navigationController.viewControllers.first === viewController
        floatingBar.isHidden = !isRootPage
        hideSystemTabBar()
    }

    private func setupFloatingBar() {
        floatingBar.backgroundColor = UIColor(hex: 0xFFFDF7)
        floatingBar.layer.cornerRadius = 29
        floatingBar.layer.borderWidth = 2
        floatingBar.layer.borderColor = UIColor.black.cgColor
        view.addSubview(floatingBar)
        floatingBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            floatingBarBottomConstraint = make.bottom.equalToSuperview().offset(-8).constraint
            make.height.equalTo(59)
        }
        floatingButtonRow.axis = .horizontal
        floatingButtonRow.alignment = .center
        floatingButtonRow.distribution = .equalSpacing
        floatingBar.addSubview(floatingButtonRow)
        floatingButtonRow.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview()
        }
        let normalImages = ["tab1", "tab2", "tab3", "tab4", "tab5"]
        let selectedImages = ["tab1_sel", "tab2_sel", "tab3_sel", "tab4 _sel", "tab5_sel"]
        let fallbackSymbols = ["house", "safari", "books.vertical", "person", "plus"]
        let actions = [0, 1, 2, 3, 4]
        for position in normalImages.indices {
            let button = UIButton(type: .custom)
            button.tag = actions[position]
            let normalImage = UIImage(named: normalImages[position])?.withRenderingMode(.alwaysOriginal)
                ?? UIImage(
                    systemName: fallbackSymbols[position],
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .medium)
                )
            let selectedImage = UIImage(named: selectedImages[position])?.withRenderingMode(.alwaysOriginal)
                ?? normalImage
            button.setImage(normalImage, for: .normal)
            button.setImage(selectedImage, for: .selected)
            button.tintColor = .black
            button.imageView?.contentMode = .scaleAspectFit
            button.backgroundColor = .clear
            button.accessibilityLabel = ["Home", "Explore", "Messages", "Me", "Publish"][position]
            button.addAction(UIAction { [weak self] _ in self?.selectFloating(button.tag) }, for: .touchUpInside)
            floatingButtonRow.addArrangedSubview(button)
            button.snp.makeConstraints { make in
                make.size.equalTo(49)
            }
            navButtons.append(button)
        }
        updateFloatingBarBottomInset()
        updateFloatingButtonSelection()
    }

    private func updateFloatingBarBottomInset() {
        guard floatingBarBottomConstraint != nil else { return }
        let actualWindowInset = view.window?.safeAreaInsets.bottom ?? 0
        guard abs(actualWindowInset - appliedWindowBottomInset) > 0.5 else { return }
        appliedWindowBottomInset = actualWindowInset
        floatingBarBottomConstraint.update(offset: -(actualWindowInset + 8))
    }

    private func selectFloating(_ tag: Int) {
        if tag >= 2, !AuthSessionStore.isSignedIn {
            presentLoginRequired()
            return
        }
        if tag == 4 {
            navButtons.enumerated().forEach { $0.element.isSelected = $0.offset == 4 }
            let editor = UINavigationController(rootViewController: PublishViewController())
            editor.modalPresentationStyle = .fullScreen
            selectedViewController?.present(editor, animated: true)
            return
        }
        selectedIndex = tag
        updateFloatingButtonSelection()
    }

    private func presentLoginRequired() {
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

    private func updateFloatingButtonSelection() {
        navButtons.enumerated().forEach { index, button in
            button.isSelected = index == selectedIndex
        }
    }
}

final class SegmentedHeaderView: UIView {
    let control: UISegmentedControl
    private let underline = UIView()
    private var underlineCenter: Constraint!
    private let contentLeadingInset: CGFloat

    init(items: [String]) {
        let usesHomeStyle = items.first == "Latest"
        contentLeadingInset = usesHomeStyle ? 0 : 20
        control = UISegmentedControl(items: items)
        super.init(frame: .zero)
        control.selectedSegmentIndex = 0
        let clear = UIImage()
        control.setBackgroundImage(clear, for: .normal, barMetrics: .default)
        control.setBackgroundImage(clear, for: .selected, barMetrics: .default)
        control.setDividerImage(clear, forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        control.selectedSegmentTintColor = .clear
        control.setTitleTextAttributes(
            [.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: usesHomeStyle ? 22 : 18, weight: .black)],
            for: .selected
        )
        control.setTitleTextAttributes(
            [.foregroundColor: UIColor(hex: 0x96938B), .font: UIFont.systemFont(ofSize: usesHomeStyle ? 18 : 16, weight: .bold)],
            for: .normal
        )
        underline.backgroundColor = UIColor(hex: 0xF0744B)
        underline.layer.cornerRadius = 2
        addSubview(control)
        addSubview(underline)
        control.pin(to: self, inset: .init(top: 0, left: contentLeadingInset, bottom: 5, right: 0))
        underline.snp.makeConstraints { make in
            underlineCenter = make.centerX.equalTo(snp.leading).offset(53).constraint
            make.bottom.equalToSuperview()
            make.width.equalTo(50)
            make.height.equalTo(4)
        }
        control.addAction(UIAction { [weak self] _ in self?.setNeedsLayout() }, for: .valueChanged)
    }
    required init?(coder: NSCoder) { nil }
    override func layoutSubviews() {
        super.layoutSubviews()
        let segment = max(1, bounds.width - contentLeadingInset) / CGFloat(max(1, control.numberOfSegments))
        underlineCenter.update(offset: contentLeadingInset + segment * (CGFloat(control.selectedSegmentIndex) + 0.5))
    }
}

private final class WornYearHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "WornYearHeaderView"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let calendarView = UIImageView(
            image: UIImage(
                systemName: "calendar",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
            )
        )
        calendarView.tintColor = .black
        calendarView.contentMode = .scaleAspectFit

        titleLabel.font = .systemFont(ofSize: 22, weight: .black)
        titleLabel.textColor = .black

        let rule = UIView()
        rule.backgroundColor = UIColor(hex: 0xDED7CE)

        let stack = UIStackView(arrangedSubviews: [calendarView, titleLabel, rule])
        stack.spacing = 10
        stack.alignment = .center
        addSubview(stack)

        calendarView.snp.makeConstraints { make in
            make.size.equalTo(25)
        }
        rule.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-4)
        }
    }

    required init?(coder: NSCoder) { nil }

    func configure(years: Int) {
        titleLabel.text = years == 1 ? "1 Year" : "\(years) Years"
    }
}

final class FeedViewController: KavoViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    enum Mode { case home, explore }
    private let mode: Mode
    private let initialSegment: Int
    private var collection: UICollectionView!
    private var selectedCategory = "Denim"
    private var selectedChannel = "Latest"
    private let flowLayout = UICollectionViewFlowLayout()
    private var headerTopConstraint: Constraint!
    private var appliedHeaderTop: CGFloat = -1
    private var pendingLikePostID: UUID?

    init(mode: Mode, initialSegment: Int = 0) {
        self.mode = mode
        self.initialSegment = initialSegment
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        let header = SegmentedHeaderView(items: mode == .home ? ["Latest", "Trending", "Worn For"] : ["Denim", "Workwear", "Biker", "Ivy"])
        header.control.selectedSegmentIndex = initialSegment
        if mode == .home { selectedChannel = header.control.titleForSegment(at: initialSegment) ?? "Latest" }
        else { selectedCategory = header.control.titleForSegment(at: initialSegment) ?? "Denim" }
        header.control.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let value = header.control.titleForSegment(at: header.control.selectedSegmentIndex) ?? ""
            if mode == .home { selectedChannel = value } else { selectedCategory = value }
            flowLayout.invalidateLayout()
            collection.reloadData()
        }, for: .valueChanged)
        flowLayout.minimumLineSpacing = 18
        flowLayout.minimumInteritemSpacing = mode == .home ? 18 : 12
        let initialTop: CGFloat = mode == .explore ? 14 : 27
        flowLayout.sectionInset = mode == .home
            ? .init(top: initialTop, left: 16, bottom: 110, right: 16)
            : .init(top: initialTop, left: 10, bottom: 110, right: 10)
        collection = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collection.backgroundColor = KavoColor.canvas
        collection.register(PostCardCell.self, forCellWithReuseIdentifier: "Post")
        collection.register(ExplorePostCell.self, forCellWithReuseIdentifier: "ExplorePost")
        collection.register(
            WornYearHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: WornYearHeaderView.reuseIdentifier
        )
        collection.dataSource = self
        collection.delegate = self
        collection.refreshControl = UIRefreshControl()
        collection.refreshControl?.addAction(UIAction { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { self?.collection.refreshControl?.endRefreshing(); self?.collection.reloadData() }
        }, for: .valueChanged)
        view.addSubview(header)
        view.addSubview(collection)
        header.snp.makeConstraints { make in
            headerTopConstraint = make.top.equalToSuperview().offset(52).constraint
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(53)
        }
        collection.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateHeaderTop()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderTop()
    }

    private func updateHeaderTop() {
        guard headerTopConstraint != nil else { return }
        let top = max(52, view.safeAreaInsets.top + 5)
        guard abs(top - appliedHeaderTop) > 0.5 else { return }
        appliedHeaderTop = top
        headerTopConstraint.update(offset: top)
    }

    private var visiblePosts: [Post] {
        if mode == .explore {
            return repository.visiblePosts.filter { post in
                if selectedCategory == "Ivy" {
                    return post.category == "Ivy" || post.category == "Ivy Style"
                }
                return post.category == selectedCategory
            }
        }
        return repository.visiblePosts
    }

    private var usesWornGrouping: Bool {
        mode == .home && selectedChannel == "Worn For"
    }

    private var wornGroups: [(years: Int, posts: [Post])] {
        let grouped = Dictionary(grouping: visiblePosts, by: \.yearsWorn)
        return grouped.keys.sorted(by: >).map { years in
            (years: years, posts: grouped[years] ?? [])
        }
    }

    private func post(at indexPath: IndexPath) -> Post {
        if usesWornGrouping {
            return wornGroups[indexPath.section].posts[indexPath.item]
        }
        return visiblePosts[indexPath.item]
    }

    override func repositoryDidChange() {
        if let postID = pendingLikePostID,
           let index = visiblePosts.firstIndex(where: { $0.id == postID }) {
            pendingLikePostID = nil
            collection?.reloadItems(at: [IndexPath(item: index, section: 0)])
        } else {
            collection?.reloadData()
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        usesWornGrouping ? wornGroups.count : 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        usesWornGrouping ? wornGroups[section].posts.count : visiblePosts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let post = post(at: indexPath)
        if mode == .explore {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExplorePost", for: indexPath) as! ExplorePostCell
            let arguments = ProcessInfo.processInfo.arguments
            let forcedUnlocked = arguments.contains("exploreUnlocked")
            let forcedLiked = arguments.contains("exploreLiked")
            cell.configure(
                with: post,
                index: indexPath.item,
                unlocked: forcedUnlocked || post.isUnlocked,
                liked: forcedLiked || post.isLiked,
                repository: repository
            )
            cell.onReport = { [weak self] in
                guard let self, requireSignedIn() else { return }
                let controller = ReportViewController()
                navigationController?.pushViewController(controller, animated: true)
            }
            cell.onComments = { [weak self] in
                guard let self, requireSignedIn() else { return }
                let controller = CommentsViewController(postID: post.id)
                navigationController?.pushViewController(controller, animated: true)
            }
            cell.onLike = { [weak self] in
                guard let self, requireSignedIn() else { return }
                pendingLikePostID = post.id
                _ = repository.toggleLike(postID: post.id)
            }
            cell.onUnlock = { [weak self] in
                guard let self, requireSignedIn() else { return }
                let detail = PostDetailViewController(postID: post.id)
                navigationController?.pushViewController(detail, animated: true)
            }
            cell.onItem = { [weak self] selectedIndex in
                guard let self, requireSignedIn() else { return }
                showItems(post.itemIDs, initialIndex: selectedIndex)
            }
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Post", for: indexPath) as! PostCardCell
        cell.configure(with: post, index: indexPath.item, channel: selectedChannel)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: WornYearHeaderView.reuseIdentifier,
            for: indexPath
        ) as! WornYearHeaderView
        header.configure(years: wornGroups[indexPath.section].years)
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard requireSignedIn() else { return }
        let detail = PostDetailViewController(postID: post(at: indexPath).id)
        navigationController?.pushViewController(detail, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if mode == .explore { return CGSize(width: collectionView.bounds.width - 20, height: 436) }
        return CGSize(width: (collectionView.bounds.width - 50) / 2, height: 338)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        usesWornGrouping ? CGSize(width: collectionView.bounds.width, height: 48) : .zero
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        guard usesWornGrouping else { return flowLayout.sectionInset }
        let isLastSection = section == wornGroups.count - 1
        return .init(top: 10, left: 16, bottom: isLastSection ? 110 : 18, right: 16)
    }

    private func showItems(_ ids: [UUID], initialIndex: Int = 0) {
        let controller = ItemDetailViewController(itemIDs: ids, initialIndex: initialIndex)
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve
        present(controller, animated: true)
    }
}

final class PostCardCell: UICollectionViewCell {
    private let artwork = UIImageView()
    private let title = UILabel()
    private let authorAvatar = UIImageView()
    private let author = UILabel()
    private let detail = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        artwork.backgroundColor = UIColor(hex: 0xECE7DE)
        artwork.contentMode = .scaleAspectFill
        artwork.clipsToBounds = true
        artwork.layer.cornerRadius = 62
        title.font = .systemFont(ofSize: 16, weight: .black)
        title.textAlignment = .center
        title.numberOfLines = 2
        title.lineBreakMode = .byTruncatingTail
        title.adjustsFontSizeToFitWidth = false
        authorAvatar.contentMode = .scaleAspectFill
        authorAvatar.clipsToBounds = true
        authorAvatar.layer.cornerRadius = 7
        authorAvatar.layer.cornerCurve = .continuous
        author.font = .systemFont(ofSize: 15, weight: .medium)
        detail.font = .systemFont(ofSize: 18, weight: .bold)
        detail.textColor = .white
        detail.textAlignment = .center
        detail.backgroundColor = .clear
        detail.layer.backgroundColor = UIColor(hex: 0xF0744B).cgColor
        detail.layer.cornerRadius = 16
        detail.layer.borderWidth = 1.5
        detail.layer.borderColor = UIColor.black.cgColor
        detail.layer.shadowColor = UIColor.black.cgColor
        detail.layer.shadowOffset = CGSize(width: 0, height: 3)
        detail.layer.shadowOpacity = 1
        detail.layer.shadowRadius = 0
        let authorRow = UIStackView(arrangedSubviews: [authorAvatar, author])
        authorRow.axis = .horizontal
        authorRow.alignment = .center
        authorRow.spacing = 6
        [artwork, title, authorRow, detail].forEach(contentView.addSubview)
        artwork.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(208)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(artwork.snp.bottom).offset(9)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
        authorAvatar.snp.makeConstraints { make in
            make.size.equalTo(24)
        }
        authorRow.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(1)
            make.centerX.equalToSuperview()
            make.height.equalTo(25)
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        detail.snp.makeConstraints { make in
            make.top.equalTo(authorRow.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(15)
            make.height.equalTo(39)
        }
    }
    required init?(coder: NSCoder) { nil }
    func configure(with post: Post, index: Int, channel: String) {
        title.text = post.title
        author.text = post.authorName
        authorAvatar.image = repositoryAvatarImage(userID: post.authorID, repository: MockRepository.shared)
        detail.text = "Details"
        let uploadedImages = (post.imageDataList ?? []).compactMap(UIImage.init(data:))
        if !uploadedImages.isEmpty {
            artwork.image = uploadedImages[index % uploadedImages.count]
        } else {
            let name = post.imageNames.isEmpty ? nil : post.imageNames[index % post.imageNames.count]
            artwork.image = post.videoThumbnailData.flatMap(UIImage.init(data:))
                ?? MockRepository.shared.postVideoURL(for: post).flatMap(kavoVideoFirstFrame)
                ?? name.flatMap(UIImage.init(named:))
                ?? postPlaceholderImage(isVideo: post.videoName != nil || post.videoLocalFileName != nil)
        }
        title.textAlignment = .center
        accessibilityLabel = "\(post.title), by \(post.authorName)"
    }
}

private func itemArchiveImage(_ item: ItemArchive?, index: Int) -> UIImage? {
    if let data = item?.imageDataList?.first, let image = UIImage(data: data) {
        return image
    }
    if let data = item?.imageData, let image = UIImage(data: data) {
        return image
    }
    if let name = item?.imageName, let image = UIImage(named: name) {
        return image
    }
    return postPlaceholderImage()
}

final class ItemArchiveChipControl: UIControl {
    init(item: ItemArchive?, index: Int) {
        super.init(frame: .zero)
        backgroundColor = UIColor(hex: 0xEEE7D6)
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor(hex: 0xCBBFA8).cgColor
        layer.shadowColor = UIColor(hex: 0xCBBFA8).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowOpacity = 1
        layer.shadowRadius = 0

        let image = UIImageView(image: itemArchiveImage(item, index: index))
        image.contentMode = .scaleAspectFit
        let label = UILabel()
        label.text = item?.name ?? "Item Archive"
        label.font = .systemFont(ofSize: 8.5, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        isAccessibilityElement = true
        accessibilityLabel = item?.name ?? "Item Archive"
        accessibilityTraits = .button
        addSubview(image)
        addSubview(label)
        image.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(7)
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(image.snp.trailing).offset(5)
            make.trailing.equalToSuperview().inset(6)
            make.centerY.equalToSuperview()
        }
        snp.makeConstraints { make in
            make.width.equalTo(126)
            make.height.equalTo(40)
        }
    }
    required init?(coder: NSCoder) { nil }
}

final class ExplorePostCell: UICollectionViewCell {
    var onReport: (() -> Void)?
    var onComments: (() -> Void)?
    var onLike: (() -> Void)?
    var onUnlock: (() -> Void)?
    var onItem: ((Int) -> Void)?

    private let card = UIView()
    private let artwork = UIImageView()
    private let avatar = UIImageView()
    private let author = UILabel()
    private let title = UILabel()
    private let body = UILabel()
    private let reportButton = UIButton(type: .system)
    private let commentButton = UIButton(type: .system)
    private let likeButton = UIButton(type: .system)
    private let unlockButton = UIButton(type: .system)
    private let unlockLabel = UILabel()
    private let videoIndicator = UIImageView()
    private let itemsScroll = UIScrollView()
    private let itemsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        card.backgroundColor = UIColor(hex: 0xF1EEE7)
        card.layer.cornerRadius = 34
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(hex: 0xDED7CE).cgColor
        contentView.addSubview(card)
        card.pin(to: contentView)

        let railBackground = UIView()
        railBackground.backgroundColor = UIColor(hex: 0xE3DFD6)
        railBackground.layer.cornerRadius = 28
        card.addSubview(railBackground)
        railBackground.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(38)
            make.width.equalTo(55)
            make.height.equalTo(210)
        }
        configureRailButton(reportButton, imageName: "report")
        configureRailButton(commentButton, imageName: "coments")
        configureRailButton(likeButton, systemSymbol: "heart.fill")
        reportButton.addAction(UIAction { [weak self] _ in self?.onReport?() }, for: .touchUpInside)
        commentButton.addAction(UIAction { [weak self] _ in self?.onComments?() }, for: .touchUpInside)
        likeButton.addAction(UIAction { [weak self] _ in self?.onLike?() }, for: .touchUpInside)
        let rail = UIStackView(arrangedSubviews: [reportButton, commentButton, likeButton])
        rail.axis = .vertical
        rail.distribution = .fillEqually
        railBackground.addSubview(rail)
        rail.snp.makeConstraints { $0.edges.equalToSuperview().inset(3) }

        artwork.contentMode = .scaleAspectFill
        artwork.clipsToBounds = true
        artwork.layer.cornerRadius = 48
        card.addSubview(artwork)
        artwork.snp.makeConstraints { make in
            make.leading.equalTo(railBackground.snp.trailing).offset(14)
            make.top.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().inset(14)
            make.height.equalTo(244)
        }
        videoIndicator.image = UIImage(
            systemName: "play.circle.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 44, weight: .bold)
        )
        videoIndicator.tintColor = UIColor.white.withAlphaComponent(0.92)
        videoIndicator.layer.shadowColor = UIColor.black.cgColor
        videoIndicator.layer.shadowOpacity = 0.35
        videoIndicator.layer.shadowRadius = 4
        card.addSubview(videoIndicator)
        videoIndicator.snp.makeConstraints { $0.center.equalTo(artwork) }

        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 8
        avatar.layer.cornerCurve = .continuous
        author.font = .systemFont(ofSize: 9, weight: .medium)
        author.textAlignment = .center
        title.font = .systemFont(ofSize: 15, weight: .black)
        title.numberOfLines = 2
        body.font = .systemFont(ofSize: 9, weight: .medium)
        body.numberOfLines = 3
        body.textColor = UIColor(hex: 0x59544D)
        [avatar, author, title, body].forEach(card.addSubview)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.top.equalTo(artwork.snp.bottom).offset(10)
            make.size.equalTo(50)
        }
        author.snp.makeConstraints { make in
            make.centerX.equalTo(avatar)
            make.top.equalTo(avatar.snp.bottom).offset(3)
        }
        title.snp.makeConstraints { make in
            make.leading.equalTo(artwork)
            make.trailing.equalToSuperview().inset(18)
            make.top.equalTo(artwork.snp.bottom).offset(10)
        }
        body.snp.makeConstraints { make in
            make.leading.trailing.equalTo(title)
            make.top.equalTo(title.snp.bottom).offset(5)
        }

        unlockButton.backgroundColor = .clear
        unlockButton.layer.backgroundColor = UIColor(hex: 0xF0744B).cgColor
        unlockButton.layer.cornerRadius = 15
        unlockButton.layer.borderWidth = 1.5
        unlockButton.layer.borderColor = UIColor.black.cgColor
        unlockButton.layer.shadowColor = UIColor.black.cgColor
        unlockButton.layer.shadowOffset = CGSize(width: 3, height: 4)
        unlockButton.layer.shadowOpacity = 1
        unlockButton.layer.shadowRadius = 0
        let unlockCoin = UIImageView(image: UIImage(named: "coin"))
        unlockCoin.contentMode = .scaleAspectFit
        unlockLabel.textColor = .white
        unlockLabel.font = .systemFont(ofSize: 18, weight: .bold)
        let unlockContent = UIStackView(arrangedSubviews: [unlockCoin, unlockLabel])
        unlockContent.axis = .horizontal
        unlockContent.alignment = .center
        unlockContent.spacing = 7
        unlockContent.isUserInteractionEnabled = false
        unlockButton.addSubview(unlockContent)
        unlockCoin.snp.makeConstraints { $0.size.equalTo(20) }
        unlockContent.snp.makeConstraints { $0.center.equalToSuperview() }
        unlockButton.addAction(UIAction { [weak self] _ in self?.onUnlock?() }, for: .touchUpInside)
        card.addSubview(unlockButton)
        unlockButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(24)
            make.height.equalTo(48)
        }

        itemsScroll.showsHorizontalScrollIndicator = false
        itemsStack.axis = .horizontal
        itemsStack.alignment = .center
        itemsStack.spacing = 8
        itemsScroll.addSubview(itemsStack)
        card.addSubview(itemsScroll)
        itemsScroll.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(25)
            make.height.equalTo(43)
        }
        itemsStack.snp.makeConstraints { make in
            make.edges.equalTo(itemsScroll.contentLayoutGuide)
            make.height.equalTo(itemsScroll.frameLayoutGuide)
        }
    }

    required init?(coder: NSCoder) { nil }

    override func prepareForReuse() {
        super.prepareForReuse()
        onReport = nil
        onComments = nil
        onLike = nil
        onUnlock = nil
        onItem = nil
        itemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    func configure(with post: Post, index: Int, unlocked: Bool, liked: Bool, repository: MockRepository) {
        let uploadedImages = (post.imageDataList ?? []).compactMap(UIImage.init(data:))
        if !uploadedImages.isEmpty {
            artwork.image = uploadedImages[index % uploadedImages.count]
        } else {
            let name = post.imageNames.isEmpty ? nil : post.imageNames[index % post.imageNames.count]
            artwork.image = post.videoThumbnailData.flatMap(UIImage.init(data:))
                ?? repository.postVideoURL(for: post).flatMap(kavoVideoFirstFrame)
                ?? name.flatMap(UIImage.init(named:))
                ?? postPlaceholderImage(isVideo: post.videoName != nil || post.videoLocalFileName != nil)
        }
        let isVideo = post.videoName != nil || post.videoLocalFileName != nil
        videoIndicator.isHidden = !isVideo
        avatar.image = repositoryAvatarImage(userID: post.authorID, repository: repository)
        author.text = post.authorName
        title.text = post.title
        body.text = post.body
        reportButton.configuration?.title = "Report"
        commentButton.configuration?.title = "\(post.comments.count)"
        likeButton.configuration?.title = formattedCount(post.likeCount)
        if var configuration = likeButton.configuration {
            configuration.baseForegroundColor = liked ? UIColor(hex: 0xFF4777) : .black
            likeButton.configuration = configuration
        }

        let hasItems = !post.itemIDs.isEmpty
        unlockButton.isHidden = unlocked || !hasItems
        itemsScroll.isHidden = !unlocked || !hasItems
        itemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if unlocked {
            for (itemIndex, itemID) in post.itemIDs.enumerated() {
                let chip = ItemArchiveChipControl(item: repository.item(id: itemID), index: itemIndex)
                chip.addAction(UIAction { [weak self] _ in self?.onItem?(itemIndex) }, for: .touchUpInside)
                itemsStack.addArrangedSubview(chip)
            }
        } else {
            unlockLabel.text = "\(post.unlockPrice)  Unlock Item Archives"
            unlockButton.accessibilityLabel = "\(post.unlockPrice) coins, Unlock Item Archives"
        }
    }

    private func configureRailButton(
        _ button: UIButton,
        imageName: String? = nil,
        systemSymbol: String? = nil
    ) {
        var configuration = UIButton.Configuration.plain()
        if let imageName {
            configuration.image = UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal)
        } else if let systemSymbol {
            configuration.image = UIImage(
                systemName: systemSymbol,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
            )
        }
        configuration.imagePlacement = .top
        configuration.imagePadding = 4
        configuration.baseForegroundColor = .black
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var value = attributes
            value.font = .systemFont(ofSize: 7, weight: .regular)
            value.foregroundColor = UIColor(hex: 0x918B82)
            return value
        }
        button.configuration = configuration
    }

    private func formattedCount(_ value: Int) -> String {
        guard value >= 1_000 else { return "\(value)" }
        return String(format: "%.1f k", Double(value) / 1_000)
    }
}

private final class PostHeroCell: UICollectionViewCell {
    static let reuseIdentifier = "PostHeroCell"
    private let imageView = UIImageView()
    private let playButton = UIButton(type: .system)
    var onPlay: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        playButton.setImage(
            UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)),
            for: .normal
        )
        playButton.tintColor = .white
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.58)
        playButton.layer.cornerRadius = 31
        playButton.addAction(UIAction { [weak self] _ in self?.onPlay?() }, for: .touchUpInside)
        contentView.addSubview(playButton)
        playButton.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(62) }
    }
    required init?(coder: NSCoder) { nil }

    override func prepareForReuse() {
        super.prepareForReuse()
        onPlay = nil
    }

    func apply(image: UIImage?, showsPlayButton: Bool) {
        imageView.image = image ?? postPlaceholderImage()
        imageView.tintColor = KavoColor.textTertiary
        imageView.backgroundColor = KavoColor.surfaceMuted
        playButton.isHidden = !showsPlayButton
    }
}

private final class PostHeroCarouselView: UIView,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    UIScrollViewDelegate {

    private let images: [UIImage]
    private let videoURL: URL?
    private let collection: UICollectionView
    private let indicatorStack = UIStackView()
    private var indicators: [UIView] = []
    var onPlayVideo: ((URL) -> Void)?

    init(
        imageNames: [String],
        imageDataList: [Data]?,
        videoName: String?,
        videoThumbnailData: Data?,
        videoURL: URL?,
        yearsWorn: Int
    ) {
        self.videoURL = videoURL
        let uploadedImages = (imageDataList ?? []).compactMap(UIImage.init(data:))
        if let videoThumbnail = videoThumbnailData.flatMap(UIImage.init(data:)) {
            images = [videoThumbnail]
        } else if let generatedVideoThumbnail = videoURL.flatMap(kavoVideoFirstFrame) {
            images = [generatedVideoThumbnail]
        } else if uploadedImages.isEmpty {
            let assetImages = imageNames.compactMap { UIImage(named: $0) }
            images = assetImages.isEmpty
                ? [postPlaceholderImage(isVideo: videoName != nil || videoURL != nil)].compactMap { $0 }
                : assetImages
        } else {
            images = uploadedImages
        }
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: .zero)

        clipsToBounds = false
        collection.clipsToBounds = true
        collection.layer.cornerRadius = 68
        collection.backgroundColor = .clear
        collection.isPagingEnabled = true
        collection.showsHorizontalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(PostHeroCell.self, forCellWithReuseIdentifier: PostHeroCell.reuseIdentifier)

        indicatorStack.axis = .horizontal
        indicatorStack.alignment = .center
        indicatorStack.spacing = 3
        for index in images.indices {
            let indicator = UIView()
            indicator.backgroundColor = index == 0 ? .black : UIColor(hex: 0xEEE7D6)
            indicator.transform = CGAffineTransform(rotationAngle: 0.17)
            indicator.snp.makeConstraints { make in
                make.width.equalTo(index == 0 ? 12 : 10)
                make.height.equalTo(9)
            }
            indicators.append(indicator)
            indicatorStack.addArrangedSubview(indicator)
        }

        let badge = UIView()
        let badgeBackground = UIImageView(image: UIImage(named: "year_bg"))
        badgeBackground.contentMode = .scaleAspectFit
        let badgeLabel = UILabel()
        badgeLabel.text = yearsWorn == 1 ? "1 year" : "\(yearsWorn) years"
        badgeLabel.font = .systemFont(ofSize: 18, weight: .black)
        badgeLabel.textAlignment = .center
        badgeLabel.transform = CGAffineTransform(rotationAngle: 0.17)
        badge.addSubview(badgeBackground)
        badge.addSubview(badgeLabel)
        badgeBackground.snp.makeConstraints { $0.edges.equalToSuperview() }
        badgeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(5)
            make.centerY.equalToSuperview().offset(-2)
        }

        addSubview(collection)
        addSubview(indicatorStack)
        addSubview(badge)
        collection.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(381)
        }
        indicatorStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(collection.snp.bottom).offset(10)
            make.height.equalTo(10)
        }
        badge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(3)
            make.top.equalToSuperview().offset(-7)
            make.size.equalTo(CGSize(width: 115, height: 78))
        }
    }
    required init?(coder: NSCoder) { nil }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostHeroCell.reuseIdentifier, for: indexPath) as! PostHeroCell
        cell.apply(image: images[indexPath.item], showsPlayButton: videoURL != nil)
        cell.onPlay = { [weak self] in
            guard let self, let videoURL else { return }
            onPlayVideo?(videoURL)
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let page = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        for (index, indicator) in indicators.enumerated() {
            indicator.backgroundColor = index == page ? .black : UIColor(hex: 0xEEE7D6)
        }
    }
}

final class PostDetailViewController: KavoViewController {
    let postID: UUID
    private let scroll = UIScrollView()
    private let content = UIStackView()
    private var contentTopConstraint: Constraint!
    private var appliedNavigationTop: CGFloat = -1

    init(postID: UUID) {
        self.postID = postID
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setup()
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setup() {
        content.axis = .vertical
        content.spacing = 16
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.addSubview(content)
        view.addSubview(scroll)
        scroll.pin(to: view)
        scroll.contentInset.bottom = 84
        scroll.verticalScrollIndicatorInsets.bottom = 84
        content.snp.makeConstraints { make in
            contentTopConstraint = make.top.equalTo(scroll.contentLayoutGuide).offset(25).constraint
            make.leading.trailing.equalTo(scroll.frameLayoutGuide).inset(20)
            make.bottom.equalTo(scroll.contentLayoutGuide).inset(28)
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updatePostNavigationTop()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePostNavigationTop()
    }

    private func updatePostNavigationTop() {
        guard contentTopConstraint != nil else { return }
        let top = view.safeAreaInsets.top + 5
        guard abs(top - appliedNavigationTop) > 0.5 else { return }
        appliedNavigationTop = top
        contentTopConstraint.update(offset: top)
    }

    override func repositoryDidChange() {
        guard repository.post(id: postID) != nil else {
            navigationController?.popViewController(animated: true)
            return
        }
        render()
    }

    private func render() {
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let post = repository.post(id: postID) else { return }
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)), for: .normal)
        back.tintColor = .black
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        let author = repository.user(id: post.authorID)
        let authorImage = repositoryAvatarImage(userID: post.authorID, repository: repository)
        let avatar = UIImageView(image: authorImage)
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 8
        avatar.layer.cornerCurve = .continuous
        avatar.clipsToBounds = true
        avatar.snp.makeConstraints { $0.size.equalTo(27) }
        let authorName = UILabel()
        authorName.text = author?.name ?? post.authorName
        authorName.font = .systemFont(ofSize: 20, weight: .medium)
        let follow = UIButton(type: .system)
        follow.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        follow.layer.cornerRadius = 9
        follow.layer.borderColor = UIColor.black.cgColor
        follow.layer.borderWidth = 1
        follow.snp.makeConstraints {
            $0.width.equalTo(72)
            $0.height.equalTo(26)
        }
        applyFollowStyle(follow, relationship: author?.relationship, isCurrentUser: post.authorID == repository.currentUser.id)
        let menu = UIButton(type: .system)
        menu.setImage(UIImage(named: "more")?.withRenderingMode(.alwaysOriginal), for: .normal)
        menu.imageView?.contentMode = .scaleAspectFit
        menu.accessibilityLabel = "More"
        menu.addAction(UIAction { [weak self] _ in self?.showPostMenu() }, for: .touchUpInside)
        let top = UIStackView(arrangedSubviews: [back, avatar, authorName, UIView(), follow, menu])
        top.spacing = 8
        top.alignment = .center
        back.snp.makeConstraints { $0.width.equalTo(28) }
        menu.snp.makeConstraints { $0.width.equalTo(28) }
        avatar.isUserInteractionEnabled = true
        authorName.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openAuthor)))
        authorName.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openAuthor)))
        content.addArrangedSubview(top)
        top.snp.makeConstraints { $0.height.equalTo(40) }
        content.setCustomSpacing(13, after: top)
        follow.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            _ = repository.toggleFollow(userID: post.authorID)
        }, for: .touchUpInside)
        let hero = PostHeroCarouselView(
            imageNames: post.imageNames,
            imageDataList: post.imageDataList,
            videoName: post.videoName,
            videoThumbnailData: post.videoThumbnailData,
            videoURL: repository.postVideoURL(for: post),
            yearsWorn: post.yearsWorn
        )
        hero.onPlayVideo = { [weak self] url in
            self?.present(VideoPlaybackViewController(url: url), animated: true)
        }
        hero.snp.makeConstraints { $0.height.equalTo(405) }
        content.addArrangedSubview(hero)
        content.setCustomSpacing(14, after: hero)
        let visualItemIDs = post.itemIDs
        if !visualItemIDs.isEmpty {
            if post.isUnlocked || post.authorID == repository.currentUser.id {
                let itemRow = makeItemArchiveRow(ids: visualItemIDs)
                content.addArrangedSubview(itemRow)
                itemRow.snp.makeConstraints { $0.height.equalTo(43) }
            } else {
                let unlock = UIButton(type: .custom)
                unlock.backgroundColor = .clear
                unlock.layer.backgroundColor = UIColor(hex: 0xF0744B).cgColor
                unlock.layer.cornerRadius = 15
                unlock.layer.borderWidth = 1.5
                unlock.layer.borderColor = UIColor.black.cgColor
                unlock.layer.shadowColor = UIColor.black.cgColor
                unlock.layer.shadowOffset = CGSize(width: 3, height: 4)
                unlock.layer.shadowOpacity = 1
                unlock.layer.shadowRadius = 0
                unlock.accessibilityLabel = "\(post.unlockPrice) coins, Unlock Item Archives"
                let coin = UIImageView(image: UIImage(named: "coin"))
                coin.contentMode = .scaleAspectFit
                let unlockTitle = UILabel()
                unlockTitle.text = "\(post.unlockPrice)  Unlock Item Archives"
                unlockTitle.textColor = .white
                unlockTitle.font = .systemFont(ofSize: 18, weight: .bold)
                let unlockContent = UIStackView(arrangedSubviews: [coin, unlockTitle])
                unlockContent.axis = .horizontal
                unlockContent.alignment = .center
                unlockContent.spacing = 7
                unlockContent.isUserInteractionEnabled = false
                unlock.addSubview(unlockContent)
                coin.snp.makeConstraints { $0.size.equalTo(20) }
                unlockContent.snp.makeConstraints { $0.center.equalToSuperview() }
                unlock.addAction(UIAction { [weak self] _ in self?.confirmUnlock() }, for: .touchUpInside)
                content.addArrangedSubview(unlock)
                unlock.snp.makeConstraints { $0.height.equalTo(46) }
                content.setCustomSpacing(20, after: unlock)
            }
        }
        let postTitle = label(post.title, .systemFont(ofSize: 23, weight: .black), KavoColor.textPrimary)
        postTitle.numberOfLines = 2
        content.addArrangedSubview(postTitle)
        let body = label(post.body, .systemFont(ofSize: 13, weight: .medium), KavoColor.textPrimary)
        body.numberOfLines = 0
        content.addArrangedSubview(body)
        let interactionRow = makePostInteractionRow(post: post)
        content.addArrangedSubview(interactionRow)
        interactionRow.snp.makeConstraints { $0.height.equalTo(30) }
        installPostInputBar()
    }

    @objc private func openAuthor() {
        guard let post = repository.post(id: postID) else { return }
        navigationController?.pushViewController(ProfileViewController(userID: post.authorID), animated: true)
    }

    private func showPostMenu() {
        guard let post = repository.post(id: postID) else { return }
        guard post.authorID != repository.currentUser.id else {
            showMessage(
                "Your Post",
                message: "This post was published by you. You cannot report or block your own account."
            )
            return
        }
        let relationship = repository.user(id: post.authorID)?.relationship
        let isFollowing = relationship == .following || relationship == .mutual
        let sheet = ChatMoreMenuViewController(
            isFollowing: isFollowing,
            onUnfollow: { [weak self] in
                guard let self else { return }
                _ = repository.toggleFollow(userID: post.authorID)
            },
            onReport: { [weak self] in
                self?.navigationController?.pushViewController(ReportViewController(), animated: true)
            },
            onBlock: { [weak self] in
                guard let self else { return }
                repository.block(userID: post.authorID)
            }
        )
        present(sheet, animated: true)
    }

    private func confirmUnlock() {
        guard let post = repository.post(id: postID) else { return }
        let prompt = UnlockPromptViewController(price: post.unlockPrice)
        prompt.onConfirm = { [weak self, weak prompt] in
            guard let self else { return }
            do {
                try repository.unlock(postID: postID)
                prompt?.dismiss(animated: true)
            }
            catch RepositoryError.insufficientCoins {
                prompt?.dismiss(animated: true)
                let alert = KavoAlertViewController(
                    title: "Insufficient Coins",
                    message: "Recharge to continue.",
                    primaryTitle: "Recharge",
                    showsCancel: true
                ) { [weak self] in
                    self?.navigationController?.pushViewController(RechargeViewController(), animated: true)
                }
                present(alert, animated: true)
            } catch { showMessage("Unable to unlock", message: error.localizedDescription) }
        }
        prompt.modalPresentationStyle = .overFullScreen
        prompt.modalTransitionStyle = .crossDissolve
        present(prompt, animated: true)
    }

    private func showItems(_ ids: [UUID], selectedIndex: Int) {
        let controller = ItemDetailViewController(itemIDs: ids, initialIndex: selectedIndex)
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve
        present(controller, animated: true)
    }

    private func makeItemArchiveRow(ids: [UUID]) -> UIView {
        let container = UIView()
        container.clipsToBounds = false
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.clipsToBounds = true
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        scroll.addSubview(row)
        container.addSubview(scroll)
        scroll.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(-10)
            make.trailing.equalToSuperview().offset(10)
        }
        row.snp.makeConstraints { make in
            make.edges.equalTo(scroll.contentLayoutGuide)
            make.height.equalTo(scroll.frameLayoutGuide)
        }
        for (index, id) in ids.enumerated() {
            let chip = ItemArchiveChipControl(item: repository.item(id: id), index: index)
            chip.addAction(UIAction { [weak self] _ in
                self?.showItems(ids, selectedIndex: index)
            }, for: .touchUpInside)
            row.addArrangedSubview(chip)
        }
        return container
    }

    private func applyFollowStyle(_ button: UIButton, relationship: RelationshipState?, isCurrentUser: Bool) {
        let isFollowing = relationship == .following || relationship == .mutual
        button.isHidden = isCurrentUser || isFollowing || relationship == .blocked
        button.setTitle("+ Follow", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: 0xF0744B)
        button.isEnabled = relationship != .blocked
    }

    private func installPostInputBar() {
        view.viewWithTag(9_143)?.removeFromSuperview()
        let bar = UIView()
        bar.tag = 9_143
        bar.backgroundColor = KavoColor.canvas
        bar.layer.cornerRadius = 18
        bar.layer.borderWidth = 2
        bar.layer.borderColor = UIColor.black.cgColor
        let prompt = UIButton(type: .system)
        prompt.setTitle("  Say something...", for: .normal)
        prompt.setImage(UIImage(named: "edit")?.withRenderingMode(.alwaysOriginal), for: .normal)
        prompt.setTitleColor(UIColor(hex: 0x625D55), for: .normal)
        prompt.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        prompt.contentHorizontalAlignment = .left
        prompt.addAction(UIAction { [weak self] _ in self?.openComments() }, for: .touchUpInside)
        bar.addSubview(prompt)
        prompt.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.height.equalTo(44)
        }
        view.addSubview(bar)
        bar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(7)
            make.height.equalTo(64)
        }
    }

    private func makePostInteractionRow(post: Post) -> UIView {
        let container = UIView()
        let commentButton = UIButton(type: .system)
        commentButton.setTitle("  \(formattedSocialCount(post.comments.count))", for: .normal)
        commentButton.setImage(UIImage(named: "comment")?.withRenderingMode(.alwaysOriginal), for: .normal)
        commentButton.setTitleColor(UIColor(hex: 0x625D55), for: .normal)
        commentButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        commentButton.addAction(UIAction { [weak self] _ in self?.openComments() }, for: .touchUpInside)

        let likeButton = UIButton(type: .system)
        likeButton.setTitle("  \(formattedSocialCount(post.likeCount))", for: .normal)
        likeButton.setImage(UIImage(systemName: post.isLiked ? "heart.fill" : "heart"), for: .normal)
        likeButton.tintColor = post.isLiked ? UIColor(hex: 0xFF4777) : UIColor(hex: 0x625D55)
        likeButton.setTitleColor(UIColor(hex: 0x625D55), for: .normal)
        likeButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        likeButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            _ = repository.toggleLike(postID: postID)
        }, for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [commentButton, likeButton])
        actions.axis = .horizontal
        actions.alignment = .center
        actions.spacing = 14
        container.addSubview(actions)
        actions.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
        }
        return container
    }

    @objc private func openComments() {
        let controller = CommentsViewController(postID: postID)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func formattedSocialCount(_ value: Int) -> String {
        guard value >= 1_000 else { return "\(value)" }
        let number = Double(value) / 1_000
        return number.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(number)) k"
            : String(format: "%.1f k", number)
    }

    private func label(_ text: String, _ font: UIFont, _ color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.adjustsFontForContentSizeCategory = true
        return label
    }
}

final class UnlockPromptViewController: UIViewController {
    var onConfirm: (() -> Void)?
    private let price: Int

    init(price: Int) {
        self.price = price
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        let dim = UIView()
        dim.backgroundColor = UIColor.black.withAlphaComponent(0.68)
        view.addSubview(dim)
        dim.pin(to: view)
        let paper = UIView()
        installAlertBackground(in: paper)
        let title = UILabel()
        title.text = "Unlock Item\nArchives"
        title.numberOfLines = 2
        title.font = .systemFont(ofSize: 28, weight: .black)
        title.textAlignment = .center
        let message = UILabel()
        message.text = "Spend \(price) Coins to unlock the\nitem archives?"
        message.font = .systemFont(ofSize: 18, weight: .black)
        message.textColor = .black
        message.textAlignment = .center
        message.numberOfLines = 0
        message.lineBreakMode = .byWordWrapping
        message.setContentCompressionResistancePriority(.required, for: .vertical)
        title.setContentCompressionResistancePriority(.required, for: .vertical)
        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.setTitleColor(.black, for: .normal)
        cancel.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        cancel.backgroundColor = UIColor(hex: 0xF4EFE7)
        cancel.layer.cornerRadius = 15
        cancel.layer.borderWidth = 1.5
        cancel.layer.borderColor = UIColor.black.cgColor
        cancel.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        let confirm = UIButton(type: .system)
        confirm.setTitle("Sure", for: .normal)
        confirm.setTitleColor(.white, for: .normal)
        confirm.titleLabel?.font = .systemFont(ofSize: 16, weight: .black)
        confirm.backgroundColor = UIColor(hex: 0xF0744B)
        confirm.layer.cornerRadius = 15
        confirm.layer.borderWidth = 1.5
        confirm.layer.borderColor = UIColor.black.cgColor
        confirm.addAction(UIAction { [weak self] _ in self?.onConfirm?() }, for: .touchUpInside)
        let buttons = UIStackView(arrangedSubviews: [cancel, confirm])
        buttons.spacing = 10
        buttons.distribution = .fillEqually
        let stack = UIStackView(arrangedSubviews: [title, message, buttons])
        stack.axis = .vertical
        stack.spacing = 16
        view.addSubview(paper)
        paper.addSubview(stack)
        paper.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview().offset(-10)
        }
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.leading.trailing.equalToSuperview().inset(25)
            make.bottom.equalToSuperview().inset(22)
        }
        buttons.snp.makeConstraints { $0.height.equalTo(54) }
    }

}

final class CommentsViewController: KavoViewController, UITableViewDataSource {
    private let postID: UUID
    private let table = UITableView(frame: .zero, style: .plain)
    private let input = KavoTextField(placeholder: "Say something...")
    private let commentCountButton = UIButton(type: .system)
    private let likeButton = UIButton(type: .system)
    private weak var commentsHeader: UIView?
    private var commentsBackTopConstraint: Constraint!
    private var commentsTitleTopConstraint: Constraint!
    private var commentsNavigationTop: CGFloat = 25
    init(postID: UUID) { self.postID = postID; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { nil }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        table.backgroundColor = KavoColor.canvas
        table.separatorStyle = .none
        table.contentInsetAdjustmentBehavior = .never
        table.dataSource = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 142
        table.register(CommentDesignCell.self, forCellReuseIdentifier: "Comment")
        let header = makeCommentsHeader()
        commentsHeader = header
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 307)
        table.tableHeaderView = header
        let bar = makeCommentsBar()
        view.addSubview(table)
        view.addSubview(bar)
        table.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bar.snp.top)
        }
        bar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-8)
            make.height.equalTo(64)
        }
        updateInteractionBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCommentsNavigationTop()
        resizeCommentsHeaderIfNeeded()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateCommentsNavigationTop()
    }

    private func updateCommentsNavigationTop() {
        guard commentsBackTopConstraint != nil, commentsTitleTopConstraint != nil else { return }
        let top = view.safeAreaInsets.top + 5
        guard abs(top - commentsNavigationTop) > 0.5 else { return }
        commentsNavigationTop = top
        commentsBackTopConstraint.update(offset: top)
        commentsTitleTopConstraint.update(offset: top + 61)
        commentsHeader?.setNeedsLayout()
    }

    private func resizeCommentsHeaderIfNeeded() {
        guard let header = commentsHeader, table.bounds.width > 0 else { return }
        header.bounds.size.width = table.bounds.width
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let fittingSize = header.systemLayoutSizeFitting(
            CGSize(width: table.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        let targetHeight = max(280 + commentsNavigationTop - 25, ceil(fittingSize.height))
        guard abs(header.frame.width - table.bounds.width) > 0.5
                || abs(header.frame.height - targetHeight) > 0.5 else { return }
        header.frame = CGRect(x: 0, y: 0, width: table.bounds.width, height: targetHeight)
        table.tableHeaderView = header
    }
    override func repositoryDidChange() {
        guard repository.post(id: postID) != nil else {
            navigationController?.popViewController(animated: true)
            return
        }
        table.reloadData()
        updateInteractionBar()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        repository.post(id: postID)?.comments.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Comment", for: indexPath) as! CommentDesignCell
        guard let comments = repository.post(id: postID)?.comments,
              comments.indices.contains(indexPath.row) else { return cell }
        let comment = comments[indexPath.row]
        let user = repository.user(id: comment.authorID)
        let displayName = user?.name ?? comment.authorName
        let avatar = repositoryAvatarImage(userID: comment.authorID, repository: repository)
        cell.configure(comment: comment, displayName: displayName, avatar: avatar)
        cell.onMore = { [weak self] in
            self?.presentCommentMenu(for: comment.authorID)
        }
        return cell
    }

    private func makeCommentsHeader() -> UIView {
        let header = UIView()
        header.backgroundColor = KavoColor.canvas
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)), for: .normal)
        back.tintColor = .black
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        let post = repository.post(id: postID)
        let postAuthor = post.flatMap { repository.user(id: $0.authorID) }
        let headerAvatar = post.map {
            repositoryAvatarImage(userID: $0.authorID, repository: repository)
        } ?? nil
        let avatar = UIImageView(image: headerAvatar)
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 8
        avatar.layer.cornerCurve = .continuous
        let author = UILabel()
        author.text = postAuthor?.name ?? post?.authorName
        author.font = .systemFont(ofSize: 20, weight: .medium)
        author.numberOfLines = 0
        let menu = UIButton(type: .system)
        menu.setImage(UIImage(named: "more")?.withRenderingMode(.alwaysOriginal), for: .normal)
        menu.imageView?.contentMode = .scaleAspectFit
        menu.accessibilityLabel = "More"
        menu.addAction(UIAction { [weak self] _ in self?.showPostAuthorMenu() }, for: .touchUpInside)
        let title = UILabel()
        title.text = post?.title
        title.font = .systemFont(ofSize: 23, weight: .black)
        title.numberOfLines = 0
        title.lineBreakMode = .byWordWrapping
        let titleArea = UIView()
        titleArea.addSubview(title)
        title.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
        let body = UILabel()
        body.text = post?.body
        body.font = .systemFont(ofSize: 13, weight: .regular)
        body.numberOfLines = 0
        body.lineBreakMode = .byWordWrapping
        body.setContentCompressionResistancePriority(.required, for: .vertical)
        let chip = UILabel()
        chip.text = post.map { "  #\($0.category)  " }
        chip.font = .systemFont(ofSize: 10, weight: .bold)
        chip.textAlignment = .center
        chip.numberOfLines = 1
        chip.backgroundColor = UIColor(hex: 0xE9D7F4)
        chip.layer.cornerRadius = 5
        chip.layer.borderWidth = 1
        chip.clipsToBounds = true
        let heading = UILabel()
        heading.text = "Comment"
        heading.font = .systemFont(ofSize: 22, weight: .black)
        let line = UIView()
        line.backgroundColor = UIColor(hex: 0xDED7CE)
        [back, avatar, author, menu, titleArea, body, chip, heading, line].forEach(header.addSubview)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            commentsBackTopConstraint = make.top.equalToSuperview().offset(commentsNavigationTop).constraint
            make.size.equalTo(44)
        }
        avatar.snp.makeConstraints { make in make.leading.equalTo(back.snp.trailing).offset(-2); make.centerY.equalTo(back); make.size.equalTo(27) }
        author.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(8)
            make.centerY.equalTo(avatar)
            make.trailing.lessThanOrEqualTo(menu.snp.leading).offset(-8)
        }
        menu.snp.makeConstraints { make in make.trailing.equalToSuperview().inset(10); make.centerY.equalTo(avatar); make.size.equalTo(44) }
        titleArea.snp.makeConstraints { make in
            commentsTitleTopConstraint = make.top.equalToSuperview().offset(commentsNavigationTop + 61).constraint
            make.leading.trailing.equalToSuperview().inset(23)
            make.height.greaterThanOrEqualTo(54)
        }
        body.snp.makeConstraints { make in
            make.top.equalTo(titleArea.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleArea)
        }
        chip.snp.makeConstraints { make in
            make.leading.equalTo(titleArea)
            make.top.equalTo(body.snp.bottom).offset(7)
            make.height.equalTo(20)
        }
        heading.snp.makeConstraints { make in
            make.leading.equalTo(titleArea)
            make.top.equalTo(chip.snp.bottom).offset(15)
            make.bottom.equalToSuperview().inset(5)
        }
        line.snp.makeConstraints { make in make.leading.equalTo(heading.snp.trailing).offset(14); make.trailing.equalToSuperview(); make.centerY.equalTo(heading); make.height.equalTo(1) }
        return header
    }

    private func makeCommentsBar() -> UIView {
        let bar = UIView()
        bar.backgroundColor = KavoColor.canvas
        bar.layer.cornerRadius = 18
        bar.layer.borderWidth = 2
        bar.layer.borderColor = UIColor.black.cgColor
        input.layer.borderWidth = 0
        input.backgroundColor = .clear
        input.font = .systemFont(ofSize: 14, weight: .medium)
        input.textColor = UIColor(hex: 0x625D55)
        let editIcon = UIImageView(image: UIImage(named: "edit"))
        editIcon.contentMode = .scaleAspectFit
        let editContainer = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 44))
        editIcon.frame = CGRect(x: 0, y: 11, width: 22, height: 22)
        editContainer.addSubview(editIcon)
        input.leftView = editContainer
        input.leftViewMode = .always
        input.returnKeyType = .send
        commentCountButton.setImage(UIImage(named: "comment")?.withRenderingMode(.alwaysOriginal), for: .normal)
        likeButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            _ = repository.toggleLike(postID: postID)
        }, for: .touchUpInside)
        let actions = UIStackView(arrangedSubviews: [commentCountButton, likeButton])
        actions.axis = .horizontal
        actions.spacing = 12
        bar.addSubview(input)
        bar.addSubview(actions)
        input.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(actions.snp.leading).offset(-8)
            make.height.equalTo(48)
        }
        actions.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
        input.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let value = input.text ?? ""
            guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            do {
                try repository.addComment(postID: postID, body: value)
                input.text = nil
            } catch {
                showMessage("Unable to comment", message: error.localizedDescription)
            }
        }, for: .editingDidEndOnExit)
        return bar
    }

    private func updateInteractionBar() {
        guard let post = repository.post(id: postID) else { return }
        commentCountButton.setImage(UIImage(named: "comment")?.withRenderingMode(.alwaysOriginal), for: .normal)
        configureCountButton(commentCountButton, symbol: nil, count: post.comments.count, color: UIColor(hex: 0x625D55))
        configureCountButton(
            likeButton,
            symbol: post.isLiked ? "heart.fill" : "heart",
            count: post.likeCount,
            color: post.isLiked ? UIColor(hex: 0xFF4777) : UIColor(hex: 0x625D55)
        )
    }

    private func configureCountButton(_ button: UIButton, symbol: String?, count: Int, color: UIColor) {
        if let symbol {
            button.setImage(UIImage(systemName: symbol), for: .normal)
        }
        button.setTitle("  \(formattedSocialCount(count))", for: .normal)
        button.tintColor = color
        button.setTitleColor(UIColor(hex: 0x625D55), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
    }

    private func showPostAuthorMenu() {
        guard let post = repository.post(id: postID) else { return }
        guard post.authorID != repository.currentUser.id else {
            showMessage(
                "Your Post",
                message: "This post was published by you. You cannot report or block your own account."
            )
            return
        }
        presentMoreMenu(for: post.authorID)
    }

    private func presentCommentMenu(for userID: UUID) {
        let sheet = ChatMoreMenuViewController(
            isFollowing: false,
            onReport: { [weak self] in
                self?.navigationController?.pushViewController(ReportViewController(), animated: true)
            },
            onBlock: { [weak self] in
                guard let self else { return }
                guard userID != repository.currentUser.id else {
                    showMessage("Unable to Block", message: "You cannot block your own account.")
                    return
                }
                repository.block(userID: userID)
            }
        )
        present(sheet, animated: true)
    }

    private func presentMoreMenu(for userID: UUID) {
        let relationship = repository.user(id: userID)?.relationship
        let isFollowing = relationship == .following || relationship == .mutual
        let sheet = ChatMoreMenuViewController(
            isFollowing: isFollowing,
            onUnfollow: { [weak self] in
                guard let self else { return }
                _ = repository.toggleFollow(userID: userID)
            },
            onReport: { [weak self] in
                self?.navigationController?.pushViewController(ReportViewController(), animated: true)
            },
            onBlock: { [weak self] in
                guard let self else { return }
                repository.block(userID: userID)
            }
        )
        present(sheet, animated: true)
    }

    private func formattedSocialCount(_ value: Int) -> String {
        guard value >= 1_000 else { return "\(value)" }
        let number = Double(value) / 1_000
        return number.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(number)) k"
            : String(format: "%.1f k", number)
    }
}

final class CommentDesignCell: UITableViewCell {
    private let avatar = UIImageView(image: kavoDefaultAvatarImage())
    private let name = UILabel()
    private let time = UILabel()
    private let bodyLabel = UILabel()
    private let menu = UIButton(type: .system)
    var onMore: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = KavoColor.canvas
        selectionStyle = .none
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 12
        avatar.layer.cornerCurve = .continuous
        name.font = .systemFont(ofSize: 18, weight: .black)
        name.numberOfLines = 0
        name.lineBreakMode = .byWordWrapping
        time.font = .systemFont(ofSize: 9)
        time.textColor = UIColor(hex: 0x9B968D)
        bodyLabel.font = .systemFont(ofSize: 11, weight: .regular)
        bodyLabel.numberOfLines = 0
        bodyLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        let moreImage = UIImage(named: "smallmore") ?? UIImage(named: "more")
        menu.setImage(moreImage?.withRenderingMode(.alwaysOriginal), for: .normal)
        menu.imageView?.contentMode = .scaleAspectFit
        menu.accessibilityLabel = "More"
        menu.addAction(UIAction { [weak self] _ in self?.onMore?() }, for: .touchUpInside)
        [avatar, name, time, bodyLabel, menu].forEach(contentView.addSubview)
        avatar.snp.makeConstraints { make in make.leading.equalToSuperview().offset(18); make.top.equalToSuperview().offset(12); make.size.equalTo(40) }
        name.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(12)
            make.top.equalTo(avatar)
            make.trailing.lessThanOrEqualTo(menu.snp.leading).offset(-8)
        }
        time.snp.makeConstraints { make in make.leading.equalTo(name); make.top.equalTo(name.snp.bottom).offset(4) }
        menu.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10)
            make.centerY.equalTo(name)
            make.size.equalTo(44)
        }
        bodyLabel.snp.makeConstraints { make in
            make.leading.equalTo(name)
            make.trailing.equalToSuperview().inset(24)
            make.top.equalTo(time.snp.bottom).offset(10)
            make.bottom.equalToSuperview().inset(18)
        }
    }
    required init?(coder: NSCoder) { nil }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMore = nil
    }

    func configure(comment: Comment, displayName: String, avatar image: UIImage?) {
        avatar.image = image ?? kavoDefaultAvatarImage()
        name.text = displayName
        time.text = Self.timeFormatter.string(from: comment.createdAt)
        bodyLabel.text = comment.body
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }()
}

private final class ItemImageCarouselCell: UICollectionViewCell {
    static let reuseIdentifier = "ItemImageCarouselCell"
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    required init?(coder: NSCoder) { nil }
}

private final class ItemImageCarouselView: UIView,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    UIScrollViewDelegate {

    private let images: [UIImage]
    private let collection: UICollectionView
    private let pageControl = UIPageControl()

    init(images: [UIImage]) {
        self.images = images.isEmpty ? [postPlaceholderImage()].compactMap { $0 } : images
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: .zero)
        collection.backgroundColor = .clear
        collection.isPagingEnabled = true
        collection.showsHorizontalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(ItemImageCarouselCell.self, forCellWithReuseIdentifier: ItemImageCarouselCell.reuseIdentifier)
        pageControl.numberOfPages = self.images.count
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.pageIndicatorTintColor = UIColor(hex: 0xD6CEC0)
        pageControl.isHidden = self.images.count <= 1
        pageControl.isUserInteractionEnabled = false
        addSubview(collection)
        addSubview(pageControl)
        collection.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(pageControl.snp.top)
        }
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(self.images.count <= 1 ? 0 : 20)
        }
    }
    required init?(coder: NSCoder) { nil }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ItemImageCarouselCell.reuseIdentifier,
            for: indexPath
        ) as! ItemImageCarouselCell
        cell.imageView.image = images[indexPath.item]
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        pageControl.currentPage = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
    }
}

final class ItemDetailViewController: KavoViewController {
    private let ids: [UUID]
    private var index: Int
    private let stack = UIStackView()

    init(itemIDs: [UUID], initialIndex: Int = 0) {
        ids = itemIDs
        index = itemIDs.indices.contains(initialIndex) ? initialIndex : 0
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .clear
        let shade = UIView()
        shade.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.addSubview(shade)
        shade.pin(to: view)
        shade.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
        stack.axis = .vertical
        stack.spacing = 12
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(93)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        render()
    }

    private func render() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard !ids.isEmpty, let item = repository.item(id: ids[index]) else { return }
        let top = UIView()
        let heading = UILabel()
        heading.text = "Item\nArchives"
        heading.textColor = .white
        heading.font = .systemFont(ofSize: 22, weight: .black)
        heading.numberOfLines = 2
        heading.lineBreakMode = .byClipping
        top.addSubview(heading)
        heading.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(17)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(110)
        }

        let thumbnailsScroll = UIScrollView()
        thumbnailsScroll.showsHorizontalScrollIndicator = false
        let thumbnailsContent = UIView()
        let thumbnails = UIStackView()
        thumbnails.axis = .horizontal
        thumbnails.alignment = .center
        thumbnails.spacing = 8
        thumbnailsContent.addSubview(thumbnails)
        thumbnailsScroll.addSubview(thumbnailsContent)
        top.addSubview(thumbnailsScroll)
        thumbnailsScroll.snp.makeConstraints { make in
            make.leading.equalTo(heading.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(14)
            make.top.bottom.equalToSuperview()
        }
        thumbnailsContent.snp.makeConstraints { make in
            make.edges.equalTo(thumbnailsScroll.contentLayoutGuide)
            make.height.equalTo(thumbnailsScroll.frameLayoutGuide)
            make.width.greaterThanOrEqualTo(thumbnailsScroll.frameLayoutGuide)
        }
        thumbnails.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
        }
        for (itemIndex, itemID) in ids.enumerated() {
            let archive = repository.item(id: itemID)
            let thumbnail = UIImageView(image: itemArchiveImage(archive, index: itemIndex))
            thumbnail.contentMode = .scaleAspectFit
            thumbnail.backgroundColor = .white
            thumbnail.layer.cornerRadius = 8
            thumbnail.clipsToBounds = true
            thumbnail.layer.borderWidth = 0
            thumbnail.tag = itemIndex
            thumbnail.isUserInteractionEnabled = true
            thumbnail.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectItem(_:))))
            thumbnails.addArrangedSubview(thumbnail)
            thumbnail.snp.makeConstraints { make in
                make.size.equalTo(40)
            }
        }
        top.snp.makeConstraints { $0.height.equalTo(72) }
        stack.addArrangedSubview(top)
        let panel = UIView()
        panel.backgroundColor = UIColor(hex: 0xF4EFE7)
        panel.layer.cornerRadius = 30
        panel.clipsToBounds = true
        let panelScroll = UIScrollView()
        panelScroll.showsVerticalScrollIndicator = false
        let panelContent = UIView()
        let carousel = ItemImageCarouselView(images: itemImages(item))
        let star = UIButton(type: .system)
        let starConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .bold)
        star.setImage(UIImage(systemName: "star", withConfiguration: starConfiguration), for: .normal)
        star.setImage(UIImage(systemName: "star.fill", withConfiguration: starConfiguration), for: .selected)
        star.tintColor = .white
        star.backgroundColor = UIColor(hex: 0xF0744B)
        star.layer.cornerRadius = 8
        star.clipsToBounds = true
        star.layer.borderWidth = 0
        star.isSelected = item.isFavorite
        star.accessibilityLabel = item.isFavorite ? "Remove from My Collection" : "Add to My Collection"
        star.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            _ = repository.toggleFavorite(itemID: item.id)
        }, for: .touchUpInside)
        let details = UILabel()
        details.numberOfLines = 0
        details.attributedText = itemDetails(item)
        details.setContentCompressionResistancePriority(.required, for: .vertical)
        panelScroll.addSubview(panelContent)
        panel.addSubview(panelScroll)
        panel.addSubview(star)
        panelContent.addSubview(carousel)
        panelContent.addSubview(details)
        panelScroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        panelContent.snp.makeConstraints { make in
            make.edges.equalTo(panelScroll.contentLayoutGuide)
            make.width.equalTo(panelScroll.frameLayoutGuide)
        }
        carousel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(48)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(271)
        }
        star.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(21)
            make.trailing.equalToSuperview().inset(25)
            make.size.equalTo(34)
        }
        details.snp.makeConstraints { make in
            make.top.equalTo(carousel.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(17)
            make.bottom.equalToSuperview().inset(28)
        }
        stack.addArrangedSubview(panel)
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    @objc private func selectItem(_ gesture: UITapGestureRecognizer) {
        guard let value = gesture.view?.tag else { return }
        index = value
        render()
    }

    override func repositoryDidChange() {
        render()
    }

    private func itemDetails(_ item: ItemArchive) -> NSAttributedString {
        let text = NSMutableAttributedString()
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = 1
        text.append(NSAttributedString(
            string: "\(item.name)\n\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .black),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraph
            ]
        ))
        let fields = [
            ("Material", item.material),
            ("Purchasing Channels", item.purchasingChannels),
            ("Care Methods", item.careMethods),
            ("Detailed Data", item.notes)
        ]
        for (label, value) in fields where !value.isEmpty {
            text.append(NSAttributedString(
                string: "\(label) :\n",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                    .foregroundColor: UIColor(hex: 0xAAA39A),
                    .paragraphStyle: paragraph
                ]
            ))
            text.append(NSAttributedString(
                string: "\(value)\n\n",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: paragraph
                ]
            ))
        }
        return text
    }

    private func itemImages(_ item: ItemArchive) -> [UIImage] {
        let images = (item.imageDataList ?? []).compactMap(UIImage.init(data:))
        if !images.isEmpty { return images }
        if let data = item.imageData, let image = UIImage(data: data) { return [image] }
        if let name = item.imageName, let image = UIImage(named: name) { return [image] }
        return [postPlaceholderImage()].compactMap { $0 }
    }
}
