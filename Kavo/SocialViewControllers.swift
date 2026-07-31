import UIKit
import SnapKit
import AVFoundation

private func socialAvatar(_ alternate: Bool = false) -> UIImage? {
    kavoDefaultAvatarImage()
}

private func socialAvatar(userID: UUID, repository: MockRepository) -> UIImage {
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

private func messagePreview(_ kind: MessageKind) -> String {
    switch kind {
    case .text(let value): return value
    case .image: return "[Photo]"
    case .voice(let seconds, _): return "[Voice] \(seconds)″"
    }
}

private final class SocialAvatarView: UIImageView {
    init(alternate: Bool = false, size: CGFloat = 48, image: UIImage? = nil) {
        super.init(image: image ?? socialAvatar(alternate))
        contentMode = .scaleAspectFill
        clipsToBounds = true
        layer.cornerRadius = max(6, size * 0.28)
        layer.cornerCurve = .continuous
        backgroundColor = KavoColor.surfaceMuted
        snp.makeConstraints { $0.size.equalTo(size) }
    }
    required init?(coder: NSCoder) { nil }
}

private final class ConversationCell: UITableViewCell {
    static let reuse = "ConversationCell"
    private let avatar = SocialAvatarView(size: 52)
    private let nameLabel = UILabel()
    private let previewLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = KavoColor.canvas
        selectionStyle = .none
        avatar.layer.cornerRadius = 16
        nameLabel.font = .systemFont(ofSize: 18, weight: .black)
        previewLabel.font = .systemFont(ofSize: 15, weight: .bold)
        previewLabel.textColor = KavoColor.textPrimary
        previewLabel.numberOfLines = 1
        previewLabel.lineBreakMode = .byTruncatingTail
        timeLabel.font = .systemFont(ofSize: 12, weight: .bold)
        timeLabel.textColor = KavoColor.textTertiary
        let copy = UIStackView(arrangedSubviews: [nameLabel, previewLabel])
        copy.axis = .vertical
        copy.spacing = 3
        contentView.addSubview(avatar)
        contentView.addSubview(copy)
        contentView.addSubview(timeLabel)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(19)
            make.centerY.equalToSuperview()
        }
        copy.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
        }
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().offset(14)
        }
    }
    required init?(coder: NSCoder) { nil }

    func apply(user: User, message: ChatMessage, repository: MockRepository) {
        avatar.image = socialAvatar(userID: user.id, repository: repository)
        nameLabel.text = user.name
        previewLabel.text = messagePreview(message.kind)
        timeLabel.text = Self.relativeFormatter.localizedString(for: message.sentAt, relativeTo: Date())
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}

private final class InteractionCell: UITableViewCell {
    static let reuse = "InteractionCell"
    private let left = SocialAvatarView(size: 54)
    private let right = UIImageView()
    private let title = UILabel()
    private let detail = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = KavoColor.canvas
        selectionStyle = .none
        left.layer.cornerRadius = 16
        right.contentMode = .scaleAspectFill
        right.clipsToBounds = true
        right.layer.cornerRadius = 18
        right.layer.cornerCurve = .continuous
        title.font = .systemFont(ofSize: 18, weight: .black)
        detail.font = .systemFont(ofSize: 13, weight: .bold)
        detail.textColor = KavoColor.textPrimary
        detail.numberOfLines = 1
        detail.lineBreakMode = .byTruncatingTail
        let copy = UIStackView(arrangedSubviews: [title, detail])
        copy.axis = .vertical
        copy.spacing = 5
        contentView.addSubview(left)
        contentView.addSubview(copy)
        contentView.addSubview(right)
        left.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(23)
            make.centerY.equalToSuperview()
        }
        copy.snp.makeConstraints { make in
            make.leading.equalTo(left.snp.trailing).offset(15)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(right.snp.leading).offset(-8)
        }
        right.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(11)
            make.centerY.equalToSuperview()
            make.size.equalTo(54)
        }
    }
    required init?(coder: NSCoder) { nil }

    func apply(user: User, detail value: String, thumbnail: UIImage?, repository: MockRepository) {
        left.image = socialAvatar(userID: user.id, repository: repository)
        title.text = user.name
        detail.text = value
        right.image = thumbnail ?? UIImage(systemName: "photo.fill")
    }
}

final class MessagesViewController: KavoViewController, UITableViewDataSource, UITableViewDelegate {
    private struct Conversation {
        let user: User
        let latestMessage: ChatMessage
    }

    private struct Interaction {
        let user: User
        let detail: String
        let thumbnail: UIImage?
    }

    enum InitialState { case chatList, interaction }
    private let initialState: InitialState
    private let segment = UISegmentedControl(items: ["CHAT LIST", "INTERACTION"])
    private let underline = UIView()
    private let table = UITableView(frame: .zero, style: .plain)
    private let pageTitle = UILabel()

    init(initialState: InitialState = .chatList) {
        self.initialState = initialState
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        pageTitle.text = "Messages"
        pageTitle.font = .systemFont(ofSize: 40, weight: .black)
        segment.selectedSegmentIndex = initialState == .chatList ? 0 : 1
        segment.selectedSegmentTintColor = .clear
        segment.backgroundColor = .clear
        segment.setBackgroundImage(UIImage(), for: .normal, barMetrics: .default)
        segment.setBackgroundImage(UIImage(), for: .selected, barMetrics: .default)
        segment.setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        segment.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: KavoColor.textTertiary], for: .normal)
        segment.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: KavoColor.textPrimary], for: .selected)
        segment.addAction(UIAction { [weak self] _ in self?.switchTab() }, for: .valueChanged)
        underline.backgroundColor = KavoColor.primary
        table.backgroundColor = KavoColor.canvas
        table.separatorColor = KavoColor.border
        table.dataSource = self
        table.delegate = self
        table.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuse)
        table.register(InteractionCell.self, forCellReuseIdentifier: InteractionCell.reuse)
        view.addSubview(pageTitle)
        view.addSubview(segment)
        view.addSubview(underline)
        view.addSubview(table)
        pageTitle.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(18)
            make.leading.equalToSuperview().offset(24)
            make.height.equalTo(48)
        }
        segment.snp.makeConstraints { make in
            make.top.equalTo(pageTitle.snp.bottom).offset(13)
            make.leading.trailing.equalToSuperview().inset(23)
            make.height.equalTo(44)
        }
        underline.snp.makeConstraints { make in
            make.top.equalTo(segment.snp.bottom)
            make.height.equalTo(2)
            make.width.equalTo(segment).dividedBy(2)
            make.leading.equalTo(segment).offset(initialState == .chatList ? 0 : (view.bounds.width - 40) / 2)
        }
        table.snp.makeConstraints { make in
            make.top.equalTo(underline.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }
        applyListStyle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func repositoryDidChange() {
        table.reloadData()
    }

    private var conversations: [Conversation] {
        repository.visibleUsers.compactMap { user in
            guard let latest = repository.messages(with: user.id).last else { return nil }
            return Conversation(user: user, latestMessage: latest)
        }
        .sorted { $0.latestMessage.sentAt > $1.latestMessage.sentAt }
    }

    private var interactions: [Interaction] {
        var values: [Interaction] = []
        for post in repository.visiblePosts where post.authorID == repository.currentUser.id {
            let thumbnail = interactionThumbnail(for: post)
            for comment in post.comments {
                guard let user = repository.user(id: comment.authorID),
                      user.id != repository.currentUser.id else { continue }
                values.append(
                    Interaction(
                        user: user,
                        detail: "commented: \(comment.body)",
                        thumbnail: thumbnail
                    )
                )
            }
            for likerID in post.likedByUserIDs ?? [] {
                guard let user = repository.user(id: likerID),
                      user.id != repository.currentUser.id else { continue }
                values.append(
                    Interaction(
                        user: user,
                        detail: "liked your post",
                        thumbnail: thumbnail
                    )
                )
            }
        }
        return values
    }

    private func interactionThumbnail(for post: Post) -> UIImage? {
        let isVideo = post.videoName != nil || post.videoLocalFileName != nil
        if isVideo {
            return post.videoThumbnailData.flatMap(UIImage.init(data:))
                ?? repository.postVideoURL(for: post).flatMap(kavoVideoFirstFrame)
                ?? UIImage(systemName: "play.rectangle.fill")
        }
        return post.imageDataList?.first.flatMap(UIImage.init(data:))
            ?? post.imageNames.first.flatMap(UIImage.init(named:))
            ?? UIImage(systemName: "photo.fill")
    }

    private func switchTab() {
        underline.snp.remakeConstraints { make in
            make.top.equalTo(segment.snp.bottom)
            make.height.equalTo(2)
            make.width.equalTo(segment).dividedBy(2)
            if segment.selectedSegmentIndex == 0 { make.leading.equalTo(segment) }
            else { make.trailing.equalTo(segment) }
        }
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
        applyListStyle()
        table.reloadData()
    }

    private func applyListStyle() {
        if segment.selectedSegmentIndex == 0 {
            table.rowHeight = 80
            table.separatorStyle = .none
            table.separatorInset = .zero
        } else {
            table.rowHeight = 108
            table.separatorStyle = .singleLine
            table.separatorInset = UIEdgeInsets(top: 0, left: 92, bottom: 0, right: 0)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        segment.selectedSegmentIndex == 0 ? conversations.count : interactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segment.selectedSegmentIndex == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuse, for: indexPath) as! ConversationCell
            let conversation = conversations[indexPath.row]
            cell.apply(user: conversation.user, message: conversation.latestMessage, repository: repository)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: InteractionCell.reuse, for: indexPath) as! InteractionCell
        let interaction = interactions[indexPath.row]
        cell.apply(user: interaction.user, detail: interaction.detail, thumbnail: interaction.thumbnail, repository: repository)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if segment.selectedSegmentIndex == 0 {
            let user = conversations[indexPath.row].user
            let chat = ChatViewController(userID: user.id)
            navigationController?.pushViewController(chat, animated: true)
        } else {
            let interaction = interactions[indexPath.row]
            let profile = ProfileViewController(userID: interaction.user.id)
            navigationController?.pushViewController(profile, animated: true)
        }
    }
}

private final class ChatBubbleCell: UITableViewCell {
    static let reuse = "ChatBubbleCell"
    var onPlayVoice: (() -> Void)?
    private let bubble = UIView()
    private let messageLabel = UILabel()
    private let mediaImage = UIImageView(image: UIImage(named: "home_latest_1"))
    private let voiceButton = UIButton(type: .custom)
    private let voiceIcon = UIImageView()
    private let voiceProgress = UIProgressView(progressViewStyle: .default)
    private let voiceDuration = UILabel()
    private let avatar = SocialAvatarView(size: 30)
    private var isVoiceMessage = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = KavoColor.canvas
        selectionStyle = .none
        bubble.backgroundColor = KavoColor.elevated
        bubble.rounded(12, border: KavoColor.textPrimary, width: 2)
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        messageLabel.numberOfLines = 0
        mediaImage.contentMode = .scaleAspectFill
        mediaImage.clipsToBounds = true
        mediaImage.rounded(24)
        contentView.addSubview(avatar)
        contentView.addSubview(bubble)
        bubble.addSubview(messageLabel)
        bubble.addSubview(mediaImage)
        voiceIcon.contentMode = .scaleAspectFit
        voiceIcon.tintColor = .white
        voiceProgress.progressTintColor = .white
        voiceProgress.trackTintColor = UIColor.black.withAlphaComponent(0.2)
        voiceProgress.layer.cornerRadius = 2
        voiceProgress.clipsToBounds = true
        voiceDuration.font = .systemFont(ofSize: 16, weight: .bold)
        voiceDuration.textColor = .white
        voiceDuration.textAlignment = .right
        bubble.addSubview(voiceIcon)
        bubble.addSubview(voiceProgress)
        bubble.addSubview(voiceDuration)
        voiceButton.backgroundColor = .clear
        voiceButton.accessibilityLabel = "Play voice message"
        voiceButton.addAction(UIAction { [weak self] _ in self?.playVoice() }, for: .touchUpInside)
        bubble.addSubview(voiceButton)
        voiceButton.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    required init?(coder: NSCoder) { nil }

    override func prepareForReuse() {
        super.prepareForReuse()
        onPlayVoice = nil
        isVoiceMessage = false
        voiceButton.isHidden = true
        voiceIcon.isHidden = true
        voiceProgress.isHidden = true
        voiceDuration.isHidden = true
        voiceProgress.progress = 0
    }

    func apply(message: ChatMessage, outgoing: Bool, avatarImage: UIImage?, mediaURL: URL?) {
        let kind = message.kind
        avatar.image = avatarImage
        messageLabel.isHidden = false
        mediaImage.isHidden = true
        isVoiceMessage = false
        voiceButton.isHidden = true
        voiceIcon.isHidden = true
        voiceProgress.isHidden = true
        voiceDuration.isHidden = true
        voiceProgress.progress = 0
        switch kind {
        case .text(let value): messageLabel.text = value
        case .image:
            messageLabel.isHidden = true
            mediaImage.isHidden = false
            if let mediaURL { mediaImage.image = UIImage(contentsOfFile: mediaURL.path) }
            else { mediaImage.image = UIImage(named: "home_latest_1") }
        case .voice(let seconds, _):
            isVoiceMessage = true
            voiceButton.isHidden = false
            messageLabel.isHidden = true
            voiceIcon.isHidden = false
            voiceProgress.isHidden = false
            voiceDuration.isHidden = false
            voiceDuration.text = "\(seconds)″"
            bubble.backgroundColor = KavoColor.primary
        }
        if case .voice = kind {
            bubble.layer.borderWidth = 2
            bubble.layer.cornerRadius = 15
        } else if case .image = kind {
            bubble.backgroundColor = .clear
            bubble.layer.borderWidth = 0
            bubble.layer.cornerRadius = 28
        } else {
            bubble.backgroundColor = KavoColor.elevated
            messageLabel.textColor = KavoColor.textPrimary
            bubble.layer.borderWidth = 2
            bubble.layer.cornerRadius = 15
        }
        avatar.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(30)
            if outgoing { make.trailing.equalToSuperview().inset(14) }
            else { make.leading.equalToSuperview().offset(14) }
        }
        switch kind {
        case .image:
            bubble.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(8)
                make.bottom.equalToSuperview().inset(8)
                make.width.equalTo(88)
                make.height.equalTo(132)
                if outgoing { make.trailing.equalTo(avatar.snp.leading).offset(-8) }
                else { make.leading.equalTo(avatar.snp.trailing).offset(8) }
            }
            messageLabel.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(0)
            }
            mediaImage.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            mediaImage.layer.cornerRadius = 28
        case .voice:
            bubble.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(8)
                make.bottom.equalToSuperview().inset(8)
                make.width.equalTo(212)
                make.height.equalTo(50)
                if outgoing { make.trailing.equalTo(avatar.snp.leading).offset(-8) }
                else { make.leading.equalTo(avatar.snp.trailing).offset(8) }
            }
            messageLabel.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(0)
            }
            mediaImage.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(0)
            }
            voiceIcon.snp.remakeConstraints {
                $0.leading.equalToSuperview().offset(18)
                $0.centerY.equalToSuperview()
                $0.size.equalTo(18)
            }
            voiceProgress.snp.remakeConstraints {
                $0.leading.equalTo(voiceIcon.snp.trailing).offset(10)
                $0.centerY.equalToSuperview()
                $0.width.equalTo(112)
            }
            voiceDuration.snp.remakeConstraints {
                $0.leading.equalTo(voiceProgress.snp.trailing).offset(10)
                $0.trailing.equalToSuperview().inset(14)
                $0.centerY.equalToSuperview()
            }
        default:
            bubble.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(8)
                make.bottom.equalToSuperview().inset(8)
                make.width.lessThanOrEqualToSuperview().multipliedBy(0.7)
                if outgoing { make.trailing.equalTo(avatar.snp.leading).offset(-8) }
                else { make.leading.equalTo(avatar.snp.trailing).offset(8) }
            }
            messageLabel.snp.remakeConstraints { $0.edges.equalToSuperview().inset(10) }
            mediaImage.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(0)
            }
        }
        updateVoicePlayback(isPlaying: false, progress: 0)
        bubble.bringSubviewToFront(voiceButton)
    }

    func updateVoicePlayback(isPlaying: Bool, progress: Float) {
        guard isVoiceMessage else { return }
        voiceIcon.image = UIImage(
            systemName: isPlaying ? "pause.fill" : "play.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        )
        voiceProgress.setProgress(min(max(progress, 0), 1), animated: false)
        voiceButton.accessibilityLabel = isPlaying ? "Pause voice message" : "Play voice message"
    }

    @objc private func playVoice() {
        guard isVoiceMessage else { return }
        onPlayVoice?()
    }
}

private final class ChatImageBubbleCell: UITableViewCell {
    static let reuse = "ChatImageBubbleCell"
    var onOpenImage: (() -> Void)?
    private let avatar = SocialAvatarView(size: 30)
    private let photo = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = KavoColor.canvas
        selectionStyle = .none
        photo.contentMode = .scaleAspectFill
        photo.clipsToBounds = true
        photo.layer.cornerRadius = 28
        contentView.addSubview(avatar)
        contentView.addSubview(photo)
        photo.isUserInteractionEnabled = true
        photo.accessibilityLabel = "View photo"
        photo.accessibilityTraits = .button
        photo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openImage)))
    }
    required init?(coder: NSCoder) { nil }

    override func prepareForReuse() {
        super.prepareForReuse()
        onOpenImage = nil
        photo.image = nil
    }

    func apply(outgoing: Bool, avatarImage: UIImage?, mediaURL: URL?) {
        avatar.image = avatarImage
        if let mediaURL {
            photo.image = UIImage(contentsOfFile: mediaURL.path)
        } else {
            photo.image = UIImage(named: "home_latest_1")
        }
        avatar.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(30)
            if outgoing {
                make.trailing.equalToSuperview().inset(14)
            } else {
                make.leading.equalToSuperview().offset(14)
            }
        }
        photo.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().inset(8)
            make.width.equalTo(88)
            make.height.equalTo(132)
            if outgoing {
                make.trailing.equalTo(avatar.snp.leading).offset(-8)
            } else {
                make.leading.equalTo(avatar.snp.trailing).offset(8)
            }
        }
    }

    @objc private func openImage() {
        onOpenImage?()
    }
}

private final class ChatImagePreviewViewController: UIViewController {
    private let image: UIImage

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }
    required init?(coder: NSCoder) { nil }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        view.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let close = UIButton(type: .system)
        close.setImage(
            UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)),
            for: .normal
        )
        close.tintColor = .white
        close.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        close.layer.cornerRadius = 22
        close.accessibilityLabel = "Close"
        close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        view.addSubview(close)
        close.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.trailing.equalToSuperview().inset(14)
            $0.size.equalTo(44)
        }
    }
}

final class ChatViewController: KavoViewController, UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate {
    enum DisplayState { case normal, moreMenu, voiceBubble, holdToTalk, releaseToSend, connect }
    private let userID: UUID
    private let displayState: DisplayState
    private let table = UITableView(frame: .zero, style: .plain)
    private let input = KavoTextField(placeholder: "Enter…")
    private let recordButton = KavoButton("Hold to Talk")
    private let modeButton = UIButton(type: .system)
    private let photoButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)
    private let inputBar = UIStackView()
    private let imagePicker = KavoImagePickerCoordinator()
    private var voiceMode = false
    private var wantsToRecord = false
    private var recordingResource: (fileName: String, url: URL)?
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var playingVoiceMessageID: UUID?
    private var voiceProgressTimer: Timer?
    private var chatMessages: [ChatMessage] { repository.messages(with: userID) }

    init(userID: UUID, displayState: DisplayState = .normal) {
        self.userID = userID
        self.displayState = displayState
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "more")?.withRenderingMode(.alwaysOriginal),
            primaryAction: UIAction { [weak self] _ in self?.showMore() }
        )
        navigationItem.titleView = makeChatTitle()
        table.backgroundColor = KavoColor.canvas
        table.separatorStyle = .none
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 88
        table.register(ChatBubbleCell.self, forCellReuseIdentifier: ChatBubbleCell.reuse)
        table.register(ChatImageBubbleCell.self, forCellReuseIdentifier: ChatImageBubbleCell.reuse)
        table.tableHeaderView = makeTimestampHeader()
        modeButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        modeButton.tintColor = KavoColor.textPrimary
        modeButton.accessibilityLabel = "Voice mode"
        photoButton.setImage(UIImage(systemName: "photo.circle.fill"), for: .normal)
        photoButton.tintColor = KavoColor.textPrimary
        photoButton.accessibilityLabel = "Send photo"
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = KavoColor.textPrimary
        sendButton.accessibilityLabel = "Send message"
        [modeButton, photoButton, sendButton].forEach { $0.snp.makeConstraints { $0.size.equalTo(44) } }
        modeButton.addAction(UIAction { [weak self] _ in self?.toggleVoice() }, for: .touchUpInside)
        photoButton.addAction(UIAction { [weak self] _ in self?.pickImage() }, for: .touchUpInside)
        sendButton.addAction(UIAction { [weak self] _ in self?.sendText() }, for: .touchUpInside)
        input.returnKeyType = .send
        input.addAction(UIAction { [weak self] _ in self?.sendText() }, for: .editingDidEndOnExit)
        imagePicker.onImagesPicked = { [weak self] images in
            guard let self, let image = images.first,
                  let data = image.jpegData(compressionQuality: 0.82) else { return }
            do {
                let fileName = try repository.storeChatImageData(data)
                if !send(.image(localPath: fileName)) {
                    repository.deleteChatMedia(fileName: fileName)
                }
            } catch {
                showMessage("Unable to send photo", message: error.localizedDescription)
            }
        }
        recordButton.isHidden = true
        recordButton.layer.borderWidth = 0
        recordButton.configuration?.cornerStyle = .fixed
        recordButton.configuration?.background.cornerRadius = 0
        recordButton.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var value = attributes
            value.font = .systemFont(ofSize: 20, weight: .bold)
            return value
        }
        recordButton.addTarget(self, action: #selector(beginRecordingTouch), for: .touchDown)
        recordButton.addTarget(self, action: #selector(finishRecordingTouch), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(cancelRecordingTouch), for: [.touchUpOutside, .touchCancel])
        inputBar.addArrangedSubview(modeButton)
        inputBar.addArrangedSubview(input)
        inputBar.addArrangedSubview(recordButton)
        inputBar.addArrangedSubview(photoButton)
        inputBar.addArrangedSubview(sendButton)
        inputBar.spacing = 4
        inputBar.alignment = .center
        inputBar.backgroundColor = KavoColor.elevated
        inputBar.layer.borderColor = KavoColor.textPrimary.cgColor
        inputBar.layer.borderWidth = 2
        inputBar.layer.cornerRadius = 19
        inputBar.clipsToBounds = true
        view.addSubview(table)
        view.addSubview(inputBar)
        table.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputBar.snp.top).offset(-8)
        }
        inputBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-8)
            make.height.equalTo(64)
        }
        applyInitialState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if displayState == .moreMenu { showMore() }
        if displayState == .connect { showConnectDialog() }
        scrollToBottom(animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioRecorder?.stop()
        stopVoicePlayback(resetProgress: true)
    }

    private func applyInitialState() {
        if displayState == .voiceBubble, let user = repository.user(id: userID), user.relationship == .mutual {
            try? repository.send(.voice(seconds: 30, localPath: nil), to: userID)
        }
        if displayState == .holdToTalk || displayState == .releaseToSend {
            voiceMode = true
            updateVoiceModeUI(isRecording: displayState == .releaseToSend)
        }
    }

    override func repositoryDidChange() {
        if repository.blockedUserIDs.contains(userID) {
            navigationController?.popViewController(animated: true)
            return
        }
        navigationItem.titleView = makeChatTitle()
        table.reloadData()
        table.tableHeaderView = makeTimestampHeader()
        scrollToBottom(animated: true)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { chatMessages.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = chatMessages[indexPath.row]
        let outgoing = message.senderID == repository.currentUser.id
        let avatarID = outgoing ? repository.currentUser.id : userID
        if case .image(let localPath) = message.kind {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ChatImageBubbleCell.reuse,
                for: indexPath
            ) as! ChatImageBubbleCell
            let mediaURL = repository.chatMediaURL(for: localPath)
            cell.apply(
                outgoing: outgoing,
                avatarImage: socialAvatar(userID: avatarID, repository: repository),
                mediaURL: mediaURL
            )
            cell.onOpenImage = { [weak self] in
                guard let self,
                      let mediaURL,
                      let image = UIImage(contentsOfFile: mediaURL.path) else {
                    self?.showMessage("Unable to open photo", message: "The local photo file is unavailable.")
                    return
                }
                present(ChatImagePreviewViewController(image: image), animated: true)
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatBubbleCell.reuse, for: indexPath) as! ChatBubbleCell
        let mediaURL: URL?
        switch message.kind {
        case .voice(_, let localPath):
            mediaURL = repository.chatMediaURL(for: localPath)
        case .text, .image:
            mediaURL = nil
        }
        cell.apply(
            message: message,
            outgoing: outgoing,
            avatarImage: socialAvatar(userID: avatarID, repository: repository),
            mediaURL: mediaURL
        )
        if case .voice(_, let localPath) = message.kind {
            let isPlaying = playingVoiceMessageID == message.id && audioPlayer?.isPlaying == true
            let progress = playingVoiceMessageID == message.id ? currentVoiceProgress : 0
            cell.updateVoicePlayback(isPlaying: isPlaying, progress: progress)
            cell.onPlayVoice = { [weak self] in
                self?.toggleVoicePlayback(messageID: message.id, fileName: localPath)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard chatMessages.indices.contains(indexPath.row) else { return }
        let message = chatMessages[indexPath.row]
        if case .voice(_, let localPath) = message.kind {
            toggleVoicePlayback(messageID: message.id, fileName: localPath)
        }
    }

    private func makeChatTitle() -> UIView {
        let avatar = SocialAvatarView(size: 24, image: socialAvatar(userID: userID, repository: repository))
        let name = UILabel()
        let user = repository.user(id: userID)
        name.text = user?.name
        name.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        let follow = UIButton(type: .system)
        let isConnected = user?.relationship == .following || user?.relationship == .mutual
        follow.setTitle("+ Follow", for: .normal)
        follow.setTitleColor(.white, for: .normal)
        follow.titleLabel?.font = UIFont.systemFont(ofSize: 9, weight: .bold)
        follow.backgroundColor = KavoColor.primary
        follow.layer.cornerRadius = 8
        follow.layer.borderColor = KavoColor.textPrimary.cgColor
        follow.layer.borderWidth = 1
        follow.isHidden = isConnected
        follow.snp.makeConstraints { make in
            make.width.equalTo(50)
            make.height.equalTo(20)
        }
        follow.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            _ = repository.toggleFollow(userID: userID)
        }, for: .touchUpInside)
        let title = UIStackView(arrangedSubviews: [avatar, name, follow])
        title.axis = .horizontal
        title.alignment = .center
        title.spacing = 5
        return title
    }

    private func toggleVoice() {
        if voiceMode {
            voiceMode = false
            updateVoiceModeUI(isRecording: false)
            return
        }
        requestMicrophonePermission { [weak self] granted in
            guard let self else { return }
            guard granted else {
                showMessage("Microphone permission", message: "Open Settings to enable recording.")
                return
            }
            voiceMode = true
            updateVoiceModeUI(isRecording: false)
        }
    }

    private func updateVoiceModeUI(isRecording: Bool) {
        input.isHidden = voiceMode
        photoButton.isHidden = voiceMode
        sendButton.isHidden = voiceMode
        recordButton.isHidden = !voiceMode
        modeButton.isHidden = voiceMode && isRecording
        if voiceMode {
            modeButton.setImage(UIImage(named: "keyboard")?.withRenderingMode(.alwaysOriginal), for: .normal)
        } else {
            modeButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        }
        inputBar.backgroundColor = voiceMode
            ? (isRecording ? UIColor(hex: 0xEEE7D6) : UIColor(hex: 0xF0744B))
            : KavoColor.elevated
        modeButton.tintColor = KavoColor.textPrimary
        recordButton.configuration?.title = isRecording ? "Release to Send" : "Hold to Talk"
        recordButton.configuration?.baseBackgroundColor = .clear
        recordButton.configuration?.baseForegroundColor = isRecording ? UIColor(hex: 0x8C826D) : .white
        recordButton.configuration?.contentInsets = isRecording
            ? .zero
            : NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 48)
    }

    private func sendText() {
        let value = input.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !value.isEmpty else { return }
        if send(.text(value)) {
            input.text = nil
        }
    }

    private func pickImage() {
        imagePicker.presentSourceSheet(from: self, sourceView: photoButton)
    }

    @objc private func beginRecordingTouch() {
        wantsToRecord = true
        requestMicrophonePermission { [weak self] granted in
            guard let self, wantsToRecord else { return }
            guard granted else {
                wantsToRecord = false
                showMessage("Microphone permission", message: "Open Settings to enable recording.")
                return
            }
            startRecording()
        }
    }

    @objc private func finishRecordingTouch() {
        wantsToRecord = false
        finishRecording(shouldSend: true)
    }

    @objc private func cancelRecordingTouch() {
        wantsToRecord = false
        finishRecording(shouldSend: false)
    }

    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        }
    }

    private func startRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
            let resource = try repository.makeChatVoiceResource()
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let recorder = try AVAudioRecorder(url: resource.url, settings: settings)
            recorder.prepareToRecord()
            guard recorder.record() else { throw RepositoryError.invalidDraft("Unable to start recording.") }
            recordingResource = resource
            audioRecorder = recorder
            updateVoiceModeUI(isRecording: true)
        } catch {
            updateVoiceModeUI(isRecording: false)
            showMessage("Unable to record", message: error.localizedDescription)
        }
    }

    private func finishRecording(shouldSend: Bool) {
        guard let recorder = audioRecorder, let resource = recordingResource else {
            updateVoiceModeUI(isRecording: false)
            return
        }
        let seconds = max(1, Int(recorder.currentTime.rounded()))
        recorder.stop()
        audioRecorder = nil
        recordingResource = nil
        updateVoiceModeUI(isRecording: false)
        if shouldSend {
            if !send(.voice(seconds: seconds, localPath: resource.fileName)) {
                repository.deleteChatMedia(fileName: resource.fileName)
            }
        } else {
            repository.deleteChatMedia(fileName: resource.fileName)
        }
    }

    private var currentVoiceProgress: Float {
        guard let player = audioPlayer, player.duration > 0 else { return 0 }
        return Float(player.currentTime / player.duration)
    }

    private func toggleVoicePlayback(messageID: UUID, fileName: String?) {
        if playingVoiceMessageID == messageID, let player = audioPlayer {
            if player.isPlaying {
                player.pause()
                stopVoiceProgressTimer()
            } else if player.play() {
                startVoiceProgressTimer()
            } else {
                showMessage("Unable to play audio", message: "The audio player could not resume.")
            }
            refreshVoiceCell(messageID: messageID)
            return
        }
        startVoicePlayback(messageID: messageID, fileName: fileName)
    }

    private func startVoicePlayback(messageID: UUID, fileName: String?) {
        guard let url = repository.chatMediaURL(for: fileName),
              FileManager.default.fileExists(atPath: url.path) else {
            showMessage("Unable to play audio", message: "The local voice file is unavailable.")
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            stopVoicePlayback(resetProgress: true)
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.volume = 1
            player.currentTime = 0
            guard player.prepareToPlay(), player.play() else {
                throw RepositoryError.invalidDraft("The audio player could not start.")
            }
            audioPlayer = player
            playingVoiceMessageID = messageID
            startVoiceProgressTimer()
            refreshVoiceCell(messageID: messageID)
        } catch {
            stopVoicePlayback(resetProgress: true)
            showMessage("Unable to play audio", message: error.localizedDescription)
        }
    }

    private func startVoiceProgressTimer() {
        stopVoiceProgressTimer()
        voiceProgressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let messageID = playingVoiceMessageID else { return }
            refreshVoiceCell(messageID: messageID)
        }
        if let voiceProgressTimer {
            RunLoop.main.add(voiceProgressTimer, forMode: .common)
        }
    }

    private func stopVoiceProgressTimer() {
        voiceProgressTimer?.invalidate()
        voiceProgressTimer = nil
    }

    private func stopVoicePlayback(resetProgress: Bool) {
        let previousID = playingVoiceMessageID
        stopVoiceProgressTimer()
        audioPlayer?.stop()
        if resetProgress {
            audioPlayer?.currentTime = 0
        }
        audioPlayer = nil
        playingVoiceMessageID = nil
        if let previousID {
            refreshVoiceCell(messageID: previousID, forcedProgress: resetProgress ? 0 : nil)
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func refreshVoiceCell(messageID: UUID, forcedProgress: Float? = nil) {
        guard let row = chatMessages.firstIndex(where: { $0.id == messageID }),
              let cell = table.cellForRow(at: IndexPath(row: row, section: 0)) as? ChatBubbleCell else { return }
        let isPlaying = playingVoiceMessageID == messageID && audioPlayer?.isPlaying == true
        let progress = forcedProgress ?? (playingVoiceMessageID == messageID ? currentVoiceProgress : 0)
        cell.updateVoicePlayback(isPlaying: isPlaying, progress: progress)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopVoicePlayback(resetProgress: true)
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        stopVoicePlayback(resetProgress: true)
        showMessage("Unable to play audio", message: error?.localizedDescription ?? "The voice file could not be decoded.")
    }

    @discardableResult
    private func send(_ kind: MessageKind) -> Bool {
        do {
            try repository.send(kind, to: userID)
            return true
        }
        catch RepositoryError.notMutual {
            showConnectDialog()
            return false
        }
        catch {
            showMessage("Can't send", message: error.localizedDescription)
            return false
        }
    }

    private func makeTimestampHeader() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 38))
        let label = UILabel()
        label.textColor = KavoColor.textTertiary
        label.font = .systemFont(ofSize: 14, weight: .medium)
        if let date = chatMessages.first?.sentAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "a hh:mm"
            label.text = formatter.string(from: date)
        }
        header.addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview() }
        return header
    }

    private func scrollToBottom(animated: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self, !chatMessages.isEmpty else { return }
            table.scrollToRow(at: IndexPath(row: chatMessages.count - 1, section: 0), at: .bottom, animated: animated)
        }
    }

    private func showConnectDialog() {
        present(KavoDecisionModalViewController(kind: .connect, primaryTitle: "Follow") { [weak self] in
            guard let self else { return }
            _ = repository.toggleFollow(userID: userID)
        }, animated: true)
    }

    private func showMore() {
        let relationship = repository.user(id: userID)?.relationship
        let isFollowing = relationship == .following || relationship == .mutual
        let sheet = ChatMoreMenuViewController(
            isFollowing: isFollowing,
            onUnfollow: { [weak self] in
                guard let self else { return }
                _ = repository.toggleFollow(userID: userID)
            },
            onReport: { [weak self] in self?.navigationController?.pushViewController(ReportViewController(), animated: true) },
            onBlock: { [weak self] in guard let self else { return }; repository.block(userID: userID) }
        )
        present(sheet, animated: true)
    }
}

final class ChatMoreMenuViewController: UIViewController {
    private let isFollowing: Bool
    private let onUnfollow: (() -> Void)?
    private let onReport: () -> Void
    private let onBlock: () -> Void

    init(
        isFollowing: Bool,
        onUnfollow: (() -> Void)? = nil,
        onReport: @escaping () -> Void,
        onBlock: @escaping () -> Void
    ) {
        self.isFollowing = isFollowing
        self.onUnfollow = onUnfollow
        self.onReport = onReport
        self.onBlock = onBlock
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    required init?(coder: NSCoder) { nil }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 29
        card.clipsToBounds = true
        let report = menuButton(title: "Report")
        let block = menuButton(title: "Block")
        let cancel = menuButton(title: "Cancel")
        var menuItems: [UIView] = []
        if isFollowing {
            let unfollow = menuButton(title: "Unfollow")
            unfollow.addAction(UIAction { [weak self] _ in
                self?.dismiss(animated: true) { self?.onUnfollow?() }
            }, for: .touchUpInside)
            unfollow.snp.makeConstraints { $0.height.equalTo(69) }
            menuItems.append(unfollow)
        }
        report.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) { self?.onReport() } }, for: .touchUpInside)
        block.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) { self?.onBlock() } }, for: .touchUpInside)
        cancel.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        let separator = UIView()
        separator.backgroundColor = UIColor(hex: 0xDEDAD4)
        menuItems.append(contentsOf: [report, block, separator, cancel])
        let stack = UIStackView(arrangedSubviews: menuItems)
        stack.axis = .vertical
        stack.spacing = 0
        stack.distribution = .fill
        view.addSubview(card)
        card.addSubview(stack)
        card.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(24)
            make.height.equalTo(isFollowing ? 285 : 216)
        }
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        report.snp.makeConstraints { $0.height.equalTo(59) }
        block.snp.makeConstraints { $0.height.equalTo(78) }
        separator.snp.makeConstraints { $0.height.equalTo(1) }
    }

    private func menuButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor(hex: 0x383634), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 21, weight: .bold)
        button.backgroundColor = .clear
        return button
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: view),
              let hitView = view.hitTest(point, with: event),
              hitView === view else {
            super.touchesEnded(touches, with: event)
            return
        }
        dismiss(animated: true)
    }
}

final class ProfileViewController: KavoViewController {
    private let userID: UUID
    private let stack = UIStackView()
    private let header = UIView()
    private let scroll = UIScrollView()
    private var isCurrentUser: Bool { userID == repository.currentUser.id }

    init(userID: UUID) {
        self.userID = userID
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        stack.axis = .vertical
        stack.spacing = 10
        scroll.alwaysBounceVertical = true
        scroll.contentInset.bottom = isCurrentUser ? 110 : 24
        scroll.verticalScrollIndicatorInsets.bottom = isCurrentUser ? 110 : 24
        scroll.addSubview(stack)
        view.addSubview(header)
        view.addSubview(scroll)
        header.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(isCurrentUser ? 18 : 0)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }
        scroll.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        stack.snp.makeConstraints { make in
            make.top.equalTo(scroll.contentLayoutGuide).offset(8)
            make.leading.trailing.equalTo(scroll.frameLayoutGuide).inset(20)
            make.bottom.equalTo(scroll.contentLayoutGuide).inset(24)
        }
        renderHeader()
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func repositoryDidChange() {
        if !isCurrentUser, repository.blockedUserIDs.contains(userID) {
            navigationController?.popViewController(animated: true)
            return
        }
        renderHeader()
        render()
    }

    private func renderHeader() {
        header.subviews.forEach { $0.removeFromSuperview() }
        if isCurrentUser {
            let title = UILabel()
            title.text = "Me"
            title.font = .systemFont(ofSize: 40, weight: .black)
            let settings = UIButton(type: .system)
            settings.setImage(UIImage(named: "setting")?.withRenderingMode(.alwaysOriginal), for: .normal)
            settings.accessibilityLabel = "Settings"
            settings.addAction(UIAction { [weak self] _ in self?.push(SettingsViewController()) }, for: .touchUpInside)
            header.addSubview(title)
            header.addSubview(settings)
            title.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(24)
                make.centerY.equalToSuperview()
            }
            settings.snp.makeConstraints { make in
                make.trailing.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
                make.size.equalTo(44)
            }
            return
        }

        let back = UIButton(type: .system)
        back.setImage(
            UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)),
            for: .normal
        )
        back.tintColor = .black
        back.accessibilityLabel = "Back"
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        let follow = UIButton(type: .system)
        applyRelationshipStyle(to: follow, relationship: repository.user(id: userID)?.relationship)
        follow.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            _ = repository.toggleFollow(userID: userID)
        }, for: .touchUpInside)
        let menu = UIButton(type: .system)
        menu.setImage(UIImage(named: "more")?.withRenderingMode(.alwaysOriginal), for: .normal)
        menu.accessibilityLabel = "More"
        menu.addAction(UIAction { [weak self] _ in self?.showProfileMenu() }, for: .touchUpInside)
        header.addSubview(back)
        header.addSubview(follow)
        header.addSubview(menu)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        menu.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        follow.snp.makeConstraints { make in
            make.trailing.equalTo(menu.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.height.equalTo(27)
            make.width.greaterThanOrEqualTo(68)
        }
    }

    private func render() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let user = repository.user(id: userID) else { return }
        title = ""
        let avatarImage = socialAvatar(userID: userID, repository: repository)
        let avatar = SocialAvatarView(size: 120, image: avatarImage)
        let avatarWrap = UIView()
        avatarWrap.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        let name = UILabel()
        name.text = user.name
        name.font = .systemFont(ofSize: 22, weight: .black)
        name.textAlignment = .center
        let bio = UILabel()
        bio.text = user.bio
        bio.font = .systemFont(ofSize: 14, weight: .regular)
        bio.textAlignment = .center
        bio.numberOfLines = 0
        let stats = makeStats(user)
        [avatarWrap, name, bio, stats].forEach(stack.addArrangedSubview)
        stack.alignment = .fill
        stack.setCustomSpacing(12, after: avatarWrap)
        stack.setCustomSpacing(6, after: name)
        stack.setCustomSpacing(18, after: bio)
        stack.setCustomSpacing(22, after: stats)
        if isCurrentUser {
            let recharge = makeRechargeBanner(balance: repository.balance)
            recharge.addAction(UIAction { [weak self] _ in self?.push(RechargeViewController()) }, for: .touchUpInside)
            let edit = makeMeMenuRow(title: "Edit Profile")
            edit.addAction(UIAction { [weak self] _ in self?.push(EditProfileViewController()) }, for: .touchUpInside)
            let posts = makeMeMenuRow(title: "My Posts")
            posts.addAction(UIAction { [weak self] _ in
                self?.push(ProfilePostListViewController(mode: .myPosts))
            }, for: .touchUpInside)
            let collection = makeMeMenuRow(title: "My Collection")
            collection.addAction(UIAction { [weak self] _ in
                self?.push(ProfilePostListViewController(mode: .collection))
            }, for: .touchUpInside)
            [recharge, edit, posts, collection].forEach(stack.addArrangedSubview)
            stack.setCustomSpacing(20, after: recharge)
            stack.setCustomSpacing(20, after: edit)
            stack.setCustomSpacing(20, after: posts)
        } else {
            let message = UIButton(type: .custom)
            message.setTitle("Message", for: .normal)
            message.setTitleColor(.white, for: .normal)
            message.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
            message.backgroundColor = KavoColor.primary
            message.layer.cornerRadius = 14
            message.layer.cornerCurve = .continuous
            message.layer.borderWidth = 1.5
            message.layer.borderColor = UIColor.black.cgColor
            message.layer.shadowColor = UIColor.black.cgColor
            message.layer.shadowOffset = CGSize(width: 0, height: 3)
            message.layer.shadowOpacity = 1
            message.layer.shadowRadius = 0
            message.snp.makeConstraints { $0.height.equalTo(52) }
            message.addAction(UIAction { [weak self] _ in guard let self else { return }; self.push(ChatViewController(userID: userID)) }, for: .touchUpInside)
            stack.addArrangedSubview(message)
            stack.setCustomSpacing(22, after: message)
            let posts = repository.visiblePosts.filter { $0.authorID == userID }
            stack.addArrangedSubview(makePostGrid(posts))
        }
    }

    private func makeStats(_ user: User) -> UIView {
        let stack = UIStackView()
        stack.distribution = .fillEqually
        let publishedLikes = repository.visiblePosts
            .filter { $0.authorID == user.id }
            .reduce(0) { $0 + $1.likeCount }
        let actualFollowing = repository.visibleUsers.filter {
            $0.relationship == .following || $0.relationship == .mutual
        }.count
        let actualFollowers = repository.visibleUsers.filter {
            $0.relationship == .followedBy || $0.relationship == .mutual
        }.count
        let values = [
            (formattedCount(isCurrentUser ? actualFollowing : user.following), "Following"),
            (formattedCount(isCurrentUser ? actualFollowers : user.followers), "Followers"),
            (formattedCount(isCurrentUser ? publishedLikes : user.likes), "Likes")
        ]
        for (index, entry) in values.enumerated() {
            let container = UIView()
            let value = UILabel()
            value.text = entry.0
            value.font = .systemFont(ofSize: 19, weight: .black)
            value.textAlignment = .center
            let label = UILabel()
            label.text = entry.1
            label.font = .systemFont(ofSize: 9, weight: .medium)
            label.textColor = KavoColor.textTertiary
            label.textAlignment = .center
            container.addSubview(value)
            container.addSubview(label)
            value.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
            }
            label.snp.makeConstraints { make in
                make.top.equalTo(value.snp.bottom).offset(3)
                make.leading.trailing.bottom.equalToSuperview()
            }
            if index > 0 {
                let separator = UIView()
                separator.backgroundColor = KavoColor.border
                container.addSubview(separator)
                separator.snp.makeConstraints { make in
                    make.leading.centerY.equalToSuperview()
                    make.width.equalTo(1)
                    make.height.equalTo(35)
                }
            }
            if isCurrentUser && index < 2 {
                container.tag = index
                container.isUserInteractionEnabled = true
                container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openRelationshipList(_:))))
                container.accessibilityLabel = entry.1
                container.accessibilityTraits = .button
            }
            stack.addArrangedSubview(container)
        }
        stack.snp.makeConstraints { $0.height.equalTo(58) }
        return stack
    }

    private func makeRechargeBanner(balance: Int) -> UIControl {
        let control = UIControl()
        let background = UIImageView(image: UIImage(named: "me_recharge"))
        background.contentMode = .scaleToFill
        background.isUserInteractionEnabled = false
        let balanceLabel = UILabel()
        balanceLabel.text = "My Balance:  \(balance)"
        balanceLabel.font = .systemFont(ofSize: 9, weight: .bold)
        balanceLabel.textColor = UIColor(hex: 0x8B713E)
        balanceLabel.textAlignment = .center
        control.addSubview(background)
        control.addSubview(balanceLabel)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }
        balanceLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(30)
            make.centerY.equalToSuperview().offset(25)
            make.width.equalTo(150)
        }
        control.snp.makeConstraints { $0.height.equalTo(92) }
        return control
    }

    private func makeMeMenuRow(title: String) -> UIControl {
        let control = UIControl()
        control.backgroundColor = UIColor(hex: 0xE9E0CC)
        control.layer.cornerRadius = 15
        control.layer.borderWidth = 1
        control.layer.borderColor = UIColor.black.cgColor
        control.layer.shadowColor = UIColor.black.cgColor
        control.layer.shadowOffset = CGSize(width: 0, height: 4)
        control.layer.shadowOpacity = 1
        control.layer.shadowRadius = 0
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = UIColor(hex: 0x8C816A)
        let chevron = UIImageView(
            image: UIImage(
                systemName: "chevron.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
            )
        )
        chevron.tintColor = .black
        control.addSubview(label)
        control.addSubview(chevron)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
        control.snp.makeConstraints { $0.height.equalTo(48) }
        return control
    }

    @objc private func openRelationshipList(_ gesture: UITapGestureRecognizer) {
        let mode: RelationshipListViewController.Mode = gesture.view?.tag == 0 ? .following : .followers
        push(RelationshipListViewController(mode: mode))
    }

    private func makePostGrid(_ posts: [Post]) -> UIView {
        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 18
        for start in stride(from: 0, to: posts.count, by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 16
            row.distribution = .fillEqually
            row.addArrangedSubview(makePostCard(posts[start]))
            if posts.indices.contains(start + 1) {
                row.addArrangedSubview(makePostCard(posts[start + 1]))
            } else {
                row.addArrangedSubview(UIView())
            }
            rows.addArrangedSubview(row)
        }
        return rows
    }

    private func makePostCard(_ post: Post) -> UIView {
        let card = UIView()
        let postImage = post.imageDataList?.first.flatMap(UIImage.init(data:))
            ?? post.videoThumbnailData.flatMap(UIImage.init(data:))
            ?? repository.postVideoURL(for: post).flatMap(kavoVideoFirstFrame)
            ?? post.imageNames.first.flatMap(UIImage.init(named:))
            ?? UIImage(systemName: post.videoName == nil && post.videoLocalFileName == nil ? "photo.fill" : "play.rectangle.fill")
        let image = UIImageView(image: postImage)
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = 48
        image.layer.cornerCurve = .continuous
        let title = UILabel()
        title.text = post.title
        title.font = .systemFont(ofSize: 15, weight: .black)
        title.textAlignment = .center
        title.numberOfLines = 2
        title.lineBreakMode = .byTruncatingTail
        let details = UIButton(type: .system)
        details.setTitle("Details", for: .normal)
        details.setTitleColor(.white, for: .normal)
        details.titleLabel?.font = .systemFont(ofSize: 17, weight: .black)
        details.backgroundColor = KavoColor.primary
        details.layer.cornerRadius = 15
        details.layer.cornerCurve = .continuous
        details.layer.borderWidth = 1.5
        details.layer.borderColor = UIColor.black.cgColor
        details.layer.shadowColor = UIColor.black.cgColor
        details.layer.shadowOffset = CGSize(width: 0, height: 3)
        details.layer.shadowOpacity = 1
        details.layer.shadowRadius = 0
        details.addAction(UIAction { [weak self] _ in
            self?.push(PostDetailViewController(postID: post.id))
        }, for: .touchUpInside)
        image.isUserInteractionEnabled = true
        image.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openPostFromGesture(_:))))
        image.tag = repository.visiblePosts.firstIndex(where: { $0.id == post.id }) ?? -1
        card.addSubview(image)
        card.addSubview(title)
        card.addSubview(details)
        image.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(210)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(image.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(2)
            make.height.equalTo(36)
        }
        details.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(7)
            make.leading.trailing.bottom.equalToSuperview().inset(7)
            make.height.equalTo(39)
        }
        return card
    }

    @objc private func openPostFromGesture(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag,
              repository.visiblePosts.indices.contains(index) else { return }
        push(PostDetailViewController(postID: repository.visiblePosts[index].id))
    }

    private func applyRelationshipStyle(to button: UIButton, relationship: RelationshipState?) {
        let isFollowing = relationship == .following || relationship == .mutual
        button.isHidden = isFollowing || relationship == .blocked
        button.setTitle("+ Follow", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 11, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = KavoColor.primary
        button.layer.cornerRadius = 9
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.black.cgColor
        button.isEnabled = relationship != .blocked
    }

    private func showProfileMenu() {
        let relationship = repository.user(id: userID)?.relationship
        let isFollowing = relationship == .following || relationship == .mutual
        let sheet = ChatMoreMenuViewController(
            isFollowing: isFollowing,
            onUnfollow: { [weak self] in
                guard let self else { return }
                _ = repository.toggleFollow(userID: userID)
            },
            onReport: { [weak self] in self?.push(ReportViewController()) },
            onBlock: { [weak self] in
                guard let self else { return }
                repository.block(userID: userID)
            }
        )
        present(sheet, animated: true)
    }

    private func formattedCount(_ value: Int) -> String {
        guard value >= 1_000 else { return "\(value)" }
        let amount = Double(value) / 1_000
        return amount.rounded() == amount
            ? String(format: "%.0f K", amount)
            : String(format: "%.1f K", amount)
    }
    private func push(_ vc: UIViewController) {
        navigationController?.pushViewController(vc, animated: true)
    }
}

private final class FavoriteItemCell: UICollectionViewCell {
    static let reuseIdentifier = "FavoriteItem"
    private let artwork = UIImageView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let favoriteBadge = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        artwork.backgroundColor = UIColor(hex: 0xECE7DE)
        artwork.contentMode = .scaleAspectFit
        artwork.clipsToBounds = true
        artwork.layer.cornerRadius = 48
        artwork.layer.cornerCurve = .continuous

        titleLabel.font = .systemFont(ofSize: 16, weight: .black)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail

        detailLabel.text = "Details"
        detailLabel.font = .systemFont(ofSize: 18, weight: .bold)
        detailLabel.textColor = .white
        detailLabel.textAlignment = .center
        detailLabel.layer.backgroundColor = KavoColor.primary.cgColor
        detailLabel.layer.cornerRadius = 16
        detailLabel.layer.borderWidth = 1.5
        detailLabel.layer.borderColor = UIColor.black.cgColor
        detailLabel.layer.shadowColor = UIColor.black.cgColor
        detailLabel.layer.shadowOffset = CGSize(width: 0, height: 3)
        detailLabel.layer.shadowOpacity = 1
        detailLabel.layer.shadowRadius = 0

        favoriteBadge.image = UIImage(
            systemName: "star.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        )
        favoriteBadge.tintColor = .white
        favoriteBadge.backgroundColor = KavoColor.primary
        favoriteBadge.contentMode = .center
        favoriteBadge.layer.cornerRadius = 10

        [artwork, titleLabel, detailLabel, favoriteBadge].forEach(contentView.addSubview)
        artwork.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(208)
        }
        favoriteBadge.snp.makeConstraints { make in
            make.top.trailing.equalTo(artwork).inset(10)
            make.size.equalTo(34)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(artwork.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(15)
            make.height.equalTo(39)
        }
    }

    required init?(coder: NSCoder) { nil }

    func configure(with item: ItemArchive) {
        titleLabel.text = item.name
        artwork.image = item.imageDataList?.first.flatMap(UIImage.init(data:))
            ?? item.imageData.flatMap(UIImage.init(data:))
            ?? item.imageName.flatMap(UIImage.init(named:))
            ?? UIImage(systemName: "photo.fill")
        accessibilityLabel = "\(item.name), saved in My Collection"
    }
}

final class ProfilePostListViewController: KavoViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {

    enum Mode {
        case myPosts
        case collection
    }

    private let mode: Mode
    private let collection: UICollectionView
    private let emptyLabel = UILabel()

    private var displayedPosts: [Post] {
        switch mode {
        case .myPosts:
            return repository.visiblePosts.filter { $0.authorID == repository.currentUser.id }
        case .collection:
            return []
        }
    }

    private var favoriteItems: [ItemArchive] {
        repository.items.filter(\.isFavorite)
    }

    init(mode: Mode) {
        self.mode = mode
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 16, left: 20, bottom: 24, right: 20)
        layout.minimumInteritemSpacing = 13
        layout.minimumLineSpacing = 18
        collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = mode == .myPosts ? "My Posts" : "My Collection"
        collection.backgroundColor = KavoColor.canvas
        collection.dataSource = self
        collection.delegate = self
        collection.register(PostCardCell.self, forCellWithReuseIdentifier: "ProfilePost")
        collection.register(FavoriteItemCell.self, forCellWithReuseIdentifier: FavoriteItemCell.reuseIdentifier)
        emptyLabel.text = mode == .myPosts ? "No posts yet" : "No saved items yet"
        emptyLabel.font = .systemFont(ofSize: 16, weight: .bold)
        emptyLabel.textColor = KavoColor.textTertiary
        emptyLabel.textAlignment = .center
        view.addSubview(collection)
        view.addSubview(emptyLabel)
        collection.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        refresh()
    }

    override func repositoryDidChange() {
        refresh()
    }

    private func refresh() {
        let isEmpty = mode == .myPosts ? displayedPosts.isEmpty : favoriteItems.isEmpty
        emptyLabel.isHidden = !isEmpty
        collection.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mode == .myPosts ? displayedPosts.count : favoriteItems.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch mode {
        case .myPosts:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ProfilePost",
                for: indexPath
            ) as! PostCardCell
            cell.configure(with: displayedPosts[indexPath.item], index: indexPath.item, channel: "")
            return cell
        case .collection:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FavoriteItemCell.reuseIdentifier,
                for: indexPath
            ) as! FavoriteItemCell
            cell.configure(with: favoriteItems[indexPath.item])
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch mode {
        case .myPosts:
            let detail = PostDetailViewController(postID: displayedPosts[indexPath.item].id)
            navigationController?.pushViewController(detail, animated: true)
        case .collection:
            let favorites = favoriteItems
            let detail = ItemDetailViewController(
                itemIDs: favorites.map(\.id),
                initialIndex: indexPath.item
            )
            present(detail, animated: true)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: (collectionView.bounds.width - 53) / 2, height: 338)
    }
}

final class EditProfileViewController: KavoViewController {
    private let name = KavoTextField(placeholder: "Enter username")
    private let bio = KavoTextField(placeholder: "Tell us about yourself")
    private let avatar = SocialAvatarView(size: 138)
    private let imagePicker = KavoImagePickerCoordinator()
    private var selectedAvatarData: Data?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        name.text = repository.currentUser.name
        bio.text = repository.currentUser.bio
        if let data = repository.currentUserAvatarData, let image = UIImage(data: data) {
            avatar.image = image
        }
        let camera = UIButton(type: .system)
        camera.setImage(UIImage(named: "carmera")?.withRenderingMode(.alwaysOriginal), for: .normal)
        camera.snp.makeConstraints { $0.size.equalTo(45) }
        camera.accessibilityLabel = "Change profile photo"
        camera.addAction(UIAction { [weak self] _ in self?.showPhotoOptions(sourceView: camera) }, for: .touchUpInside)
        avatar.isUserInteractionEnabled = true
        avatar.accessibilityLabel = "Profile photo"
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changeAvatar)))
        imagePicker.onImagesPicked = { [weak self] images in
            guard let self, let image = images.first else { return }
            avatar.image = image
            selectedAvatarData = image.jpegData(compressionQuality: 0.82)
        }
        let avatarWrap = UIView()
        avatarWrap.addSubview(avatar)
        avatarWrap.addSubview(camera)
        avatar.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        camera.snp.makeConstraints { make in
            make.trailing.bottom.equalTo(avatar)
        }
        let userTitle = UILabel()
        userTitle.text = "USERNAME"
        userTitle.font = .systemFont(ofSize: 16, weight: .bold)
        userTitle.textColor = KavoColor.primary
        let bioTitle = UILabel()
        bioTitle.text = "BIO"
        bioTitle.font = .systemFont(ofSize: 16, weight: .bold)
        bioTitle.textColor = KavoColor.primary
        [name, bio].forEach { field in
            field.backgroundColor = .clear
            field.font = .systemFont(ofSize: 16, weight: .semibold)
            field.layer.cornerRadius = 10
            field.layer.borderWidth = 1.5
            field.layer.borderColor = UIColor(hex: 0xE5DFD6).cgColor
            field.attributedPlaceholder = NSAttributedString(
                string: field.placeholder ?? "",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                    .foregroundColor: UIColor(hex: 0xC5C0B9)
                ]
            )
            field.snp.makeConstraints { $0.height.equalTo(59) }
        }
        let save = UIButton(type: .custom)
        save.setTitle("Save Changes", for: .normal)
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
            guard let self, let value = name.text, (2...30).contains(value.count) else {
                self?.showMessage("Display Name must be 2–30 characters.")
                return
            }
            repository.updateProfile(
                name: value,
                bio: String((bio.text ?? "").prefix(160)),
                avatarData: selectedAvatarData
            )
            navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)
        let fields = UIStackView(arrangedSubviews: [avatarWrap, userTitle, name, bioTitle, bio])
        fields.axis = .vertical
        fields.spacing = 0
        fields.setCustomSpacing(24, after: avatarWrap)
        fields.setCustomSpacing(12, after: userTitle)
        fields.setCustomSpacing(17, after: name)
        fields.setCustomSpacing(12, after: bioTitle)
        view.addSubview(fields)
        view.addSubview(save)
        fields.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(28)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        save.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
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

    @objc private func changeAvatar() {
        showPhotoOptions(sourceView: avatar)
    }

    private func showPhotoOptions(sourceView: UIView) {
        imagePicker.presentSourceSheet(from: self, sourceView: sourceView)
    }
}

private final class RechargeTierCell: UICollectionViewCell {
    static let reuseIdentifier = "RechargeTierCell"
    private let card = UIView()
    private let coin = UIImageView(image: UIImage(named: "coin"))
    private let topBackground = UIView()
    private let amount = UILabel()
    private let pricePill = UIView()
    private let price = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.black.cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 0
        topBackground.backgroundColor = UIColor(hex: 0xEDE3CE)
        topBackground.layer.cornerRadius = 11
        topBackground.layer.cornerCurve = .continuous
        topBackground.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        topBackground.clipsToBounds = true
        coin.contentMode = .scaleAspectFit
        amount.font = .systemFont(ofSize: 20, weight: .bold)
        amount.textColor = KavoColor.textPrimary
        amount.textAlignment = .center
        amount.adjustsFontSizeToFitWidth = true
        amount.minimumScaleFactor = 0.7
        pricePill.backgroundColor = KavoColor.primary
        pricePill.layer.cornerRadius = 8.5
        pricePill.layer.cornerCurve = .continuous
        price.font = .systemFont(ofSize: 10, weight: .bold)
        price.textColor = .white
        price.textAlignment = .center
        contentView.addSubview(card)
        card.addSubview(topBackground)
        card.addSubview(coin)
        card.addSubview(amount)
        card.addSubview(pricePill)
        pricePill.addSubview(price)
        card.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(4)
        }
        topBackground.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(1)
            make.height.equalTo(52)
        }
        coin.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(7)
            make.centerX.equalToSuperview()
            make.size.equalTo(44)
        }
        amount.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(58)
            make.leading.trailing.equalToSuperview().inset(5)
            make.height.equalTo(24)
        }
        pricePill.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(85)
            make.centerX.equalToSuperview()
            make.height.equalTo(17)
        }
        price.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(8)
        }
    }

    required init?(coder: NSCoder) { nil }

    func apply(amount value: String, price priceValue: String) {
        amount.text = value
        price.text = priceValue
    }
}

final class RechargeViewController: KavoViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let purchaseManager = InAppPurchaseManager.shared
    private var collection: UICollectionView!
    private let balanceAmount = UILabel()
    private let emptyLabel = UILabel()
    private let loadingOverlay = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let loadingLabel = UILabel()
    private var notificationTokens: [NSObjectProtocol] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Recharge"
        let balance = UIView()
        balance.backgroundColor = UIColor(hex: 0xFFF7E5)
        balance.layer.cornerRadius = 12
        balance.layer.cornerCurve = .continuous
        balance.layer.borderColor = KavoColor.textPrimary.cgColor
        balance.layer.borderWidth = 1
        balance.layer.shadowColor = UIColor.black.cgColor
        balance.layer.shadowOffset = CGSize(width: 0, height: 3)
        balance.layer.shadowOpacity = 1
        balance.layer.shadowRadius = 0
        let balanceCoin = UIImageView(image: UIImage(named: "coin"))
        balanceCoin.contentMode = .scaleAspectFit
        balanceAmount.text = "\(repository.balance)"
        balanceAmount.font = UIFont.systemFont(ofSize: 38, weight: .bold)
        balanceAmount.textAlignment = .right
        let current = UILabel()
        current.text = "Current Balance"
        current.font = UIFont.systemFont(ofSize: 14)
        current.textAlignment = .right
        balance.addSubview(balanceCoin)
        balance.addSubview(balanceAmount)
        balance.addSubview(current)
        balanceCoin.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(46)
        }
        balanceAmount.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().inset(18)
        }
        current.snp.makeConstraints { make in
            make.top.equalTo(balanceAmount.snp.bottom).offset(-5)
            make.trailing.equalTo(balanceAmount)
        }
        let caption = UILabel()
        caption.text = "Recharge Tiers"
        caption.font = .systemFont(ofSize: 20, weight: .regular)
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = KavoColor.canvas
        collection.dataSource = self
        collection.delegate = self
        collection.register(RechargeTierCell.self, forCellWithReuseIdentifier: RechargeTierCell.reuseIdentifier)
        view.addSubview(balance)
        view.addSubview(caption)
        view.addSubview(collection)
        balance.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(80)
        }
        caption.snp.makeConstraints { make in
            make.top.equalTo(balance.snp.bottom).offset(22)
            make.leading.equalToSuperview().offset(16)
        }
        collection.snp.makeConstraints { make in
            make.top.equalTo(caption.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }
        configureEmptyState()
        configureLoadingOverlay()
        bindPurchaseNotifications()
        purchaseManager.start()
        updateContent()
    }

    deinit {
        notificationTokens.forEach(NotificationCenter.default.removeObserver)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: KavoColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 28, weight: .bold)
        ]
        balanceAmount.text = "\(repository.balance)"
        if purchaseManager.products.isEmpty, purchaseManager.state == .idle {
            purchaseManager.fetchProducts()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: KavoColor.textPrimary,
            .font: KavoFont.title3
        ]
    }

    override func repositoryDidChange() {
        balanceAmount.text = "\(repository.balance)"
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        purchaseManager.products.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: RechargeTierCell.reuseIdentifier,
            for: indexPath
        ) as! RechargeTierCell
        let item = purchaseManager.products[indexPath.item]
        cell.apply(amount: item.displayName, price: item.displayPrice)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard purchaseManager.products.indices.contains(indexPath.item) else { return }
        purchaseManager.purchase(productID: purchaseManager.products[indexPath.item].identifier)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: (collectionView.bounds.width - 48) / 3, height: 113)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        .init(top: 8, left: 16, bottom: 24, right: 12)
    }

    private func configureEmptyState() {
        emptyLabel.text = "Loading recharge products…"
        emptyLabel.textColor = KavoColor.textTertiary
        emptyLabel.font = KavoFont.body
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.center.equalTo(collection)
            $0.leading.trailing.equalToSuperview().inset(36)
        }
    }

    private func configureLoadingOverlay() {
        loadingOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        loadingOverlay.isHidden = true
        loadingIndicator.color = .white
        loadingLabel.textColor = .white
        loadingLabel.font = KavoFont.headline
        loadingLabel.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [loadingIndicator, loadingLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        loadingOverlay.addSubview(stack)
        view.addSubview(loadingOverlay)
        loadingOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        stack.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    private func bindPurchaseNotifications() {
        let center = NotificationCenter.default
        notificationTokens.append(
            center.addObserver(
                forName: InAppPurchaseManager.productsDidChange,
                object: purchaseManager,
                queue: .main
            ) { [weak self] _ in self?.updateContent() }
        )
        notificationTokens.append(
            center.addObserver(
                forName: InAppPurchaseManager.stateDidChange,
                object: purchaseManager,
                queue: .main
            ) { [weak self] _ in self?.updatePurchaseState() }
        )
        notificationTokens.append(
            center.addObserver(
                forName: InAppPurchaseManager.purchaseSucceeded,
                object: purchaseManager,
                queue: .main
            ) { [weak self] notification in
                guard let self else { return }
                let amount = notification.userInfo?["coinAmount"] as? Int ?? 0
                balanceAmount.text = "\(repository.balance)"
                showMessage("Recharge Complete", message: "\(amount) coins added.")
            }
        )
        notificationTokens.append(
            center.addObserver(
                forName: InAppPurchaseManager.purchaseFailed,
                object: purchaseManager,
                queue: .main
            ) { [weak self] notification in
                guard let self, viewIfLoaded?.window != nil else { return }
                let message = notification.userInfo?["message"] as? String ?? "Please try again later."
                showMessage("Purchase Unavailable", message: message)
                updateContent()
            }
        )
    }

    private func updateContent() {
        collection.reloadData()
        let isLoading = purchaseManager.state == .loadingProducts
        emptyLabel.text = isLoading
            ? "Loading recharge products…"
            : "No recharge products are currently available."
        emptyLabel.isHidden = !purchaseManager.products.isEmpty
        updatePurchaseState()
    }

    private func updatePurchaseState() {
        switch purchaseManager.state {
        case .loadingProducts:
            showLoading("Loading products…")
        case .purchasing:
            showLoading("Processing purchase…")
        case .deferred:
            hideLoading()
            if viewIfLoaded?.window != nil {
                showMessage("Purchase Pending", message: "This purchase is waiting for approval.")
            }
        case .idle:
            hideLoading()
        }
    }

    private func showLoading(_ text: String) {
        loadingLabel.text = text
        loadingOverlay.isHidden = false
        loadingIndicator.startAnimating()
        collection.isUserInteractionEnabled = false
    }

    private func hideLoading() {
        loadingIndicator.stopAnimating()
        loadingOverlay.isHidden = true
        collection.isUserInteractionEnabled = true
    }
}
