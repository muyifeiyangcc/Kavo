import UIKit
import SnapKit
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

final class PublishSession {
    var draft = PublishDraft()
}

private enum PublishStyle {
    static let background = UIColor(hex: 0xFFFCF5)
    static let panel = UIColor(hex: 0xF3F0E9)
    static let line = UIColor(hex: 0xD8D3C9)
    static let muted = UIColor(hex: 0xBDB8AE)
    static let chip = UIColor(hex: 0xEDE7D9)
    static let purple = UIColor(hex: 0xE7D4F3)
    static let pink = UIColor(hex: 0xFF4767)
}

private extension UILabel {
    static func publishLabel(_ text: String = "", size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        return label
    }
}

private final class PublishTextField: UITextField {
    init(placeholder: String, size: CGFloat = 16) {
        super.init(frame: .zero)
        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: PublishStyle.muted, .font: UIFont.systemFont(ofSize: size, weight: .semibold)]
        )
        textColor = .black
        font = .systemFont(ofSize: size, weight: .semibold)
        borderStyle = .none
        autocorrectionType = .no
    }
    required init?(coder: NSCoder) { nil }
}

private final class PublishMultilineField: UITextView, UITextViewDelegate {
    private let placeholderLabel: UILabel

    init(placeholder: String, size: CGFloat = 16) {
        placeholderLabel = UILabel.publishLabel(placeholder, size: size, weight: .semibold, color: PublishStyle.muted)
        super.init(frame: .zero, textContainer: nil)
        backgroundColor = .clear
        font = .systemFont(ofSize: size, weight: .semibold)
        textColor = .black
        textContainerInset = UIEdgeInsets(top: 12, left: 0, bottom: 8, right: 0)
        textContainer.lineFragmentPadding = 0
        isScrollEnabled = false
        delegate = self
        addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { nil }

    func setValue(_ value: String) {
        text = value
        placeholderLabel.isHidden = !value.isEmpty
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

private final class PublishMediaPickerCoordinator: NSObject,
    PHPickerViewControllerDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {

    var onPhotosPicked: (([UIImage]) -> Void)?
    var onVideoPicked: ((URL, UIImage) -> Void)?
    var onError: ((String) -> Void)?
    private weak var presenter: UIViewController?

    func present(from presenter: UIViewController, sourceView: UIView) {
        self.presenter = presenter
        let sheet = UIAlertController(title: "Add Media", message: "Choose up to 3 photos or 1 video.", preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sheet.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                self?.presentCamera()
            })
        }
        sheet.addAction(UIAlertAction(title: "Choose Photos (Up to 3)", style: .default) { [weak self] _ in
            self?.presentLibrary(filter: .images, selectionLimit: 3)
        })
        sheet.addAction(UIAlertAction(title: "Choose Video (1)", style: .default) { [weak self] _ in
            self?.presentLibrary(filter: .videos, selectionLimit: 1)
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }
        presenter.present(sheet, animated: true)
    }

    private func presentCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        picker.videoMaximumDuration = 60
        picker.videoQuality = .typeHigh
        picker.delegate = self
        presenter?.present(picker, animated: true)
    }

    private func presentLibrary(filter: PHPickerFilter, selectionLimit: Int) {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = filter
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
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            picker.dismiss(animated: true) { [weak self] in self?.onPhotosPicked?([image]) }
            return
        }
        guard let sourceURL = info[.mediaURL] as? URL else {
            picker.dismiss(animated: true)
            return
        }
        do {
            let copiedURL = try Self.copyToTemporaryLocation(sourceURL)
            let thumbnail = try Self.videoThumbnail(url: copiedURL)
            picker.dismiss(animated: true) { [weak self] in
                self?.onVideoPicked?(copiedURL, thumbnail)
            }
        } catch {
            picker.dismiss(animated: true) { [weak self] in
                self?.onError?("Unable to read this video.")
            }
        }
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !results.isEmpty else {
            picker.dismiss(animated: true)
            return
        }
        if results.count == 1,
           results[0].itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            results[0].itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self, weak picker] url, _ in
                guard let self, let url else {
                    DispatchQueue.main.async {
                        picker?.dismiss(animated: true)
                        self?.onError?("Unable to read this video.")
                    }
                    return
                }
                do {
                    let copiedURL = try Self.copyToTemporaryLocation(url)
                    let thumbnail = try Self.videoThumbnail(url: copiedURL)
                    DispatchQueue.main.async {
                        picker?.dismiss(animated: true) {
                            self.onVideoPicked?(copiedURL, thumbnail)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        picker?.dismiss(animated: true)
                        self.onError?("Unable to generate the video cover.")
                    }
                }
            }
            return
        }

        let group = DispatchGroup()
        let lock = NSLock()
        var indexedImages: [(Int, UIImage)] = []
        for (index, result) in results.prefix(3).enumerated()
        where result.itemProvider.canLoadObject(ofClass: UIImage.self) {
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
                if images.isEmpty {
                    self?.onError?("Unable to read the selected photos.")
                } else {
                    self?.onPhotosPicked?(images)
                }
            }
        }
    }

    private static func copyToTemporaryLocation(_ sourceURL: URL) throws -> URL {
        let fileExtension = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("KavoPublish-\(UUID().uuidString).\(fileExtension)")
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return destination
    }

    private static func videoThumbnail(url: URL) throws -> UIImage {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 900, height: 900)
        let image = try generator.copyCGImage(at: CMTime(seconds: 0.1, preferredTimescale: 600), actualTime: nil)
        return UIImage(cgImage: image)
    }
}

private final class MediaStageView: UIView {
    let uploadButton = UIButton(type: .system)
    var onRemovePhoto: ((Int) -> Void)?
    var onRemoveVideo: (() -> Void)?
    var onPlayVideo: (() -> Void)?
    private let mediaStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = PublishStyle.background
        let title = UILabel.publishLabel("Photos / Video", size: 15, weight: .bold)
        title.alpha = 0;
        let rule = UILabel.publishLabel("Up to 3 photos or 1 video", size: 10, weight: .medium, color: PublishStyle.muted)
        rule.alpha = 0;
        addSubview(title)
        addSubview(rule)
        title.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(68)
            $0.top.equalToSuperview().offset(4)
        }
        rule.snp.makeConstraints {
            $0.leading.equalTo(title)
            $0.top.equalTo(title.snp.bottom).offset(2)
        }

        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        mediaStack.axis = .horizontal
        mediaStack.spacing = 10
        scroll.addSubview(mediaStack)
        addSubview(scroll)
        scroll.snp.makeConstraints {
            $0.top.equalTo(rule.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(18)
            $0.bottom.equalToSuperview().inset(8)
        }
        mediaStack.snp.makeConstraints {
            $0.edges.equalTo(scroll.contentLayoutGuide)
            $0.height.equalTo(scroll.frameLayoutGuide)
        }
        configureUploadButton()
        render(photos: [], videoThumbnail: nil)
    }
    required init?(coder: NSCoder) { nil }

    func render(photos: [UIImage], videoThumbnail: UIImage?) {
        mediaStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let videoThumbnail {
            mediaStack.addArrangedSubview(makeMediaCard(image: videoThumbnail, index: 0, isVideo: true))
        } else {
            for (index, image) in photos.enumerated() {
                mediaStack.addArrangedSubview(makeMediaCard(image: image, index: index, isVideo: false))
            }
        }
        if videoThumbnail == nil && photos.count < 3 {
            mediaStack.addArrangedSubview(uploadButton)
        }
    }

    private func configureUploadButton() {
        uploadButton.backgroundColor = PublishStyle.chip
        uploadButton.layer.cornerRadius = 12
        uploadButton.layer.borderWidth = 1
        uploadButton.layer.borderColor = UIColor(hex: 0xCEC4B0).cgColor
        uploadButton.tintColor = .black
        let uploadIcon = UIImageView(image: UIImage(systemName: "photo.on.rectangle.angled", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold)))
        uploadIcon.tintColor = .black
        uploadIcon.contentMode = .scaleAspectFit
        uploadIcon.isUserInteractionEnabled = false
        let uploadLabel = UILabel.publishLabel("Add Photos\nor Video", size: 11, weight: .bold)
        uploadLabel.textAlignment = .center
        uploadLabel.numberOfLines = 2
        uploadLabel.isUserInteractionEnabled = false
        uploadButton.addSubview(uploadIcon)
        uploadButton.addSubview(uploadLabel)
        uploadIcon.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(28)
            $0.size.equalTo(34)
        }
        uploadLabel.snp.makeConstraints {
            $0.top.equalTo(uploadIcon.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(100)
        }
        uploadButton.snp.makeConstraints {
            $0.width.equalTo(126)
            $0.height.equalTo(148)
        }
    }

    private func makeMediaCard(image: UIImage, index: Int, isVideo: Bool) -> UIView {
        let card = UIView()
        card.backgroundColor = PublishStyle.chip
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(hex: 0xCEC4B0).cgColor
        card.clipsToBounds = true
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        card.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        if isVideo {
            let play = UIButton(type: .system)
            play.setImage(
                UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)),
                for: .normal
            )
            play.tintColor = .white
            play.backgroundColor = UIColor.black.withAlphaComponent(0.58)
            play.layer.cornerRadius = 25
            play.addAction(UIAction { [weak self] _ in self?.onPlayVideo?() }, for: .touchUpInside)
            card.addSubview(play)
            play.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(50) }
        }

        let remove = UIButton(type: .system)
        remove.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)), for: .normal)
        remove.tintColor = .white
        remove.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        remove.layer.cornerRadius = 13
        remove.addAction(UIAction { [weak self] _ in
            if isVideo { self?.onRemoveVideo?() }
            else { self?.onRemovePhoto?(index) }
        }, for: .touchUpInside)
        card.addSubview(remove)
        remove.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(7)
            $0.size.equalTo(26)
        }
        card.snp.makeConstraints { $0.width.equalTo(126); $0.height.equalTo(148) }
        return card
    }
}

private final class YearSelectorView: UIView {
    var onSelection: ((Int) -> Void)?
    private let years = [5, 4, 3, 2, 1]
    private var labels: [UILabel] = []
    private let pointer = UIView()

    init(selected: Int) {
        super.init(frame: .zero)
        backgroundColor = PublishStyle.panel
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        for value in years {
            let label = UILabel.publishLabel(value == 5 ? "5 Years" : "\(value) Years", size: value == selected ? 16 : 12, weight: .bold, color: value == selected ? .black : UIColor(hex: 0xC4BDAE))
            label.textAlignment = .center
            label.tag = value
            label.isUserInteractionEnabled = true
            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectYear(_:))))
            stack.addArrangedSubview(label)
            label.snp.makeConstraints { $0.width.equalTo(value == 3 ? 76 : 67) }
            labels.append(label)
        }
        pointer.backgroundColor = PublishStyle.background
        pointer.transform = CGAffineTransform(rotationAngle: .pi / 4)
        addSubview(pointer)
        updateSelection(selected)
    }
    required init?(coder: NSCoder) { nil }

    @objc private func selectYear(_ gesture: UITapGestureRecognizer) {
        guard let value = gesture.view?.tag else { return }
        updateSelection(value)
        onSelection?(value)
    }

    private func updateSelection(_ selected: Int) {
        labels.forEach {
            $0.textColor = $0.tag == selected ? .black : UIColor(hex: 0xC4BDAE)
            $0.font = .systemFont(ofSize: $0.tag == selected ? 16 : 12, weight: .bold)
        }
        guard let selectedLabel = labels.first(where: { $0.tag == selected }) else { return }
        pointer.snp.remakeConstraints {
            $0.centerX.equalTo(selectedLabel)
            $0.centerY.equalTo(snp.top)
            $0.size.equalTo(12)
        }
    }
}

private final class ItemChipView: UIControl {
    init(item: ItemArchive, index: Int) {
        super.init(frame: .zero)
        backgroundColor = PublishStyle.chip
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor(hex: 0xCEC4B0).cgColor
        let itemImage = item.imageData.flatMap(UIImage.init(data:))
            ?? item.imageName.flatMap(UIImage.init(named:))
            ?? UIImage(systemName: "photo.fill")
        let image = UIImageView(image: itemImage)
        image.contentMode = .scaleAspectFit
        let label = UILabel.publishLabel(item.name, size: 7.5, weight: .bold)
        label.numberOfLines = 2
        addSubview(image)
        addSubview(label)
        image.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(7)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(22)
        }
        label.snp.makeConstraints {
            $0.leading.equalTo(image.snp.trailing).offset(4)
            $0.trailing.equalToSuperview().inset(6)
            $0.centerY.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { nil }
}

final class PublishViewController: KavoViewController, UITextViewDelegate {
    private let session: PublishSession
    private let mediaPicker = PublishMediaPickerCoordinator()
    private let mediaStage = MediaStageView()
    private var selectedPhotos: [UIImage] = []
    private var selectedVideoThumbnail: UIImage?
    private let titleField = PublishTextField(placeholder: "Title: Enter theme")
    private let bodyView = UITextView()
    private let countLabel = UILabel.publishLabel("0/500", size: 12, weight: .semibold, color: PublishStyle.muted)
    private let itemsScroll = UIScrollView()
    private let itemsStack = UIStackView()
    private let categoryStack = UIStackView()
    private let categoryScroll = UIScrollView()
    private let itemChevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let categories = ["Denim", "Workwear", "Biker", "Ivy Style"]
    private var selectedCategory = "Denim"
    private var categoryButtons: [UIButton] = []

    init(draft: PublishDraft = PublishDraft()) {
        session = PublishSession()
        session.draft = draft
        selectedCategory = draft.category ?? "Denim"
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = PublishStyle.background
        navigationController?.setNavigationBarHidden(true, animated: false)
        build()
        populateDraft()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateItems()
    }

    private func build() {
        view.addSubview(mediaStage)
        mediaStage.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(196)
        }

        let close = UIButton(type: .system)
        close.tintColor = .black
        close.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)), for: .normal)
        close.addAction(UIAction { [weak self] _ in self?.askToClose() }, for: .touchUpInside)
        view.addSubview(close)
        close.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(25)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(3)
            $0.size.equalTo(44)
        }

        mediaStage.uploadButton.addAction(UIAction { [weak self] _ in self?.pickMedia() }, for: .touchUpInside)
        mediaPicker.onPhotosPicked = { [weak self] images in
            guard let self else { return }
            let wasVideo = session.draft.videoURL != nil
            clearTemporaryVideo()
            if wasVideo {
                selectedPhotos = []
            }
            let availableSlots = max(0, 3 - selectedPhotos.count)
            selectedPhotos.append(contentsOf: images.prefix(availableSlots))
            selectedVideoThumbnail = nil
            session.draft.photoCount = selectedPhotos.count
            session.draft.photoData = selectedPhotos.compactMap { $0.jpegData(compressionQuality: 0.78) }
            session.draft.videoURL = nil
            session.draft.videoThumbnailData = nil
            mediaStage.render(photos: selectedPhotos, videoThumbnail: nil)
        }
        mediaPicker.onVideoPicked = { [weak self] url, thumbnail in
            guard let self else { return }
            clearTemporaryVideo()
            selectedPhotos = []
            selectedVideoThumbnail = thumbnail
            session.draft.photoCount = 0
            session.draft.photoData = []
            session.draft.videoURL = url
            session.draft.videoThumbnailData = thumbnail.jpegData(compressionQuality: 0.8)
            mediaStage.render(photos: [], videoThumbnail: thumbnail)
        }
        mediaPicker.onError = { [weak self] message in
            self?.showMessage("Unable to add media", message: message)
        }
        mediaStage.onRemovePhoto = { [weak self] index in
            guard let self, selectedPhotos.indices.contains(index) else { return }
            selectedPhotos.remove(at: index)
            session.draft.photoCount = selectedPhotos.count
            session.draft.photoData = selectedPhotos.compactMap { $0.jpegData(compressionQuality: 0.78) }
            mediaStage.render(photos: selectedPhotos, videoThumbnail: nil)
        }
        mediaStage.onRemoveVideo = { [weak self] in
            guard let self else { return }
            clearTemporaryVideo()
            selectedVideoThumbnail = nil
            session.draft.videoURL = nil
            session.draft.videoThumbnailData = nil
            mediaStage.render(photos: [], videoThumbnail: nil)
        }
        mediaStage.onPlayVideo = { [weak self] in
            guard let self, let url = session.draft.videoURL else { return }
            present(VideoPlaybackViewController(url: url), animated: true)
        }

        let yearSelector = YearSelectorView(selected: session.draft.yearsWorn)
        yearSelector.onSelection = { [weak self] year in self?.session.draft.yearsWorn = year }
        view.addSubview(yearSelector)
        yearSelector.snp.makeConstraints {
            $0.top.equalTo(mediaStage.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(50)
        }
        let form = UIView()
        view.addSubview(form)
        form.snp.makeConstraints {
            $0.top.equalTo(yearSelector.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        form.addSubview(titleField)
        titleField.snp.makeConstraints {
            $0.top.equalToSuperview().offset(7)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(43)
        }
        addLine(to: form, topAnchor: titleField.snp.bottom)

        bodyView.backgroundColor = .clear
        bodyView.textContainerInset = .zero
        bodyView.textContainer.lineFragmentPadding = 0
        bodyView.font = .systemFont(ofSize: 15, weight: .semibold)
        bodyView.textColor = PublishStyle.muted
        bodyView.delegate = self
        form.addSubview(bodyView)
        bodyView.snp.makeConstraints {
            $0.top.equalTo(titleField.snp.bottom).offset(19)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(118)
        }
        form.addSubview(countLabel)
        countLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(24)
            $0.top.equalTo(bodyView.snp.bottom).offset(-2)
        }
        addLine(to: form, topAnchor: bodyView.snp.bottom, offset: 16)

        let itemTitle = UILabel.publishLabel("Item Archives", size: 16, weight: .bold)
        form.addSubview(itemTitle)
        itemTitle.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.top.equalTo(bodyView.snp.bottom).offset(35)
            $0.height.equalTo(26)
        }
        itemChevron.tintColor = .black
        itemChevron.contentMode = .scaleAspectFit
        form.addSubview(itemChevron)
        itemChevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(19)
            $0.centerY.equalTo(itemTitle)
            $0.size.equalTo(18)
        }
        itemsScroll.showsHorizontalScrollIndicator = false
        form.addSubview(itemsScroll)
        itemsScroll.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(164)
            $0.trailing.equalTo(itemChevron.snp.leading).offset(-4)
            $0.centerY.equalTo(itemTitle)
            $0.height.equalTo(43)
        }
        itemsStack.axis = .horizontal
        itemsStack.alignment = .center
        itemsStack.spacing = 6
        itemsScroll.addSubview(itemsStack)
        itemsStack.snp.makeConstraints {
            $0.edges.equalTo(itemsScroll.contentLayoutGuide)
            $0.height.equalTo(itemsScroll.frameLayoutGuide)
        }
        [itemTitle, itemChevron].forEach {
            $0.isUserInteractionEnabled = true
            $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openItems)))
        }
        addLine(to: form, topAnchor: itemTitle.snp.bottom, offset: 10)

        let categoryTitle = UILabel.publishLabel("Category", size: 16, weight: .bold)
        form.addSubview(categoryTitle)
        categoryTitle.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.top.equalTo(itemTitle.snp.bottom).offset(24)
        }
        categoryStack.axis = .horizontal
        categoryStack.spacing = 9
        for (index, category) in categories.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle("#\(category)", for: .normal)
            button.setTitleColor(UIColor(hex: 0x695477), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 11, weight: .bold)
            button.layer.cornerRadius = 9
            button.layer.borderWidth = 1.2
            button.layer.borderColor = UIColor(hex: 0xC9BEAA).cgColor
            button.addAction(UIAction { [weak self] _ in self?.chooseCategory(index) }, for: .touchUpInside)
            button.snp.makeConstraints {
                $0.width.equalTo(category == "Workwear" || category == "Ivy Style" ? 78 : 67)
                $0.height.equalTo(23)
            }
            categoryButtons.append(button)
            categoryStack.addArrangedSubview(button)
        }
        categoryScroll.showsHorizontalScrollIndicator = false
        form.addSubview(categoryScroll)
        categoryScroll.addSubview(categoryStack)
        categoryScroll.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(138)
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(categoryTitle)
            $0.height.equalTo(27)
        }
        categoryStack.snp.makeConstraints {
            $0.edges.equalTo(categoryScroll.contentLayoutGuide)
            $0.height.equalTo(categoryScroll.frameLayoutGuide)
        }
        addLine(to: form, topAnchor: categoryTitle.snp.bottom, offset: 16)

        let save = UIButton(type: .system)
        save.setTitle("Save", for: .normal)
        save.setTitleColor(.black, for: .normal)
        save.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        save.backgroundColor = .white
        save.layer.cornerRadius = 20
        save.layer.borderWidth = 1
        save.layer.borderColor = UIColor.black.cgColor
        save.layer.shadowColor = UIColor.black.cgColor
        save.layer.shadowOpacity = 1
        save.layer.shadowOffset = CGSize(width: 3, height: 4)
        save.layer.shadowRadius = 0
        save.addAction(UIAction { [weak self] _ in self?.publish() }, for: .touchUpInside)
        form.addSubview(save)
        save.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(6)
            $0.height.equalTo(67)
        }
        chooseCategory(categories.firstIndex(of: selectedCategory) ?? 0)
    }

    private func addLine(to container: UIView, topAnchor: ConstraintItem, offset: CGFloat = 0) {
        let line = UIView()
        line.backgroundColor = PublishStyle.line
        container.addSubview(line)
        line.snp.makeConstraints {
            $0.top.equalTo(topAnchor).offset(offset)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(1)
        }
    }

    private func populateDraft() {
        let isLinkedPreviewSeed = session.draft.title == "The Wardrobe Staple That Never Fades" &&
            session.draft.itemIDs.count == 2
        let displayedTitle = isLinkedPreviewSeed ? "" : session.draft.title
        let displayedBody = isLinkedPreviewSeed ? "" : session.draft.body
        titleField.text = displayedTitle
        bodyView.text = displayedBody.isEmpty ? "Content:Please enter..." : displayedBody
        bodyView.textColor = displayedBody.isEmpty ? PublishStyle.muted : .black
        countLabel.text = "\(displayedBody.count)/500"
        if !session.draft.photoData.isEmpty {
            selectedPhotos = session.draft.photoData.compactMap(UIImage.init(data:))
            session.draft.photoCount = selectedPhotos.count
            mediaStage.render(photos: selectedPhotos, videoThumbnail: nil)
        } else if let thumbnailData = session.draft.videoThumbnailData,
                  let thumbnail = UIImage(data: thumbnailData) {
            selectedVideoThumbnail = thumbnail
            mediaStage.render(photos: [], videoThumbnail: thumbnail)
        }
        updateItems()
    }

    private func chooseCategory(_ index: Int) {
        categoryButtons.enumerated().forEach { buttonIndex, button in
            button.backgroundColor = buttonIndex == index ? PublishStyle.purple : PublishStyle.chip
            button.layer.borderColor = (buttonIndex == index ? UIColor.black : UIColor(hex: 0xC9BEAA)).cgColor
            button.layer.borderWidth = buttonIndex == index ? 1.8 : 1
        }
        guard categories.indices.contains(index) else { return }
        selectedCategory = categories[index]
    }

    private func pickMedia() {
        mediaPicker.present(from: self, sourceView: mediaStage.uploadButton)
    }

    private func clearTemporaryVideo() {
        guard let url = session.draft.videoURL,
              url.path.hasPrefix(FileManager.default.temporaryDirectory.path) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    @objc private func openItems() {
        presentItemEditor(itemID: nil)
    }

    private func presentItemEditor(itemID: UUID?) {
        let editor = ItemEditorViewController(session: session, itemID: itemID)
        editor.onSaved = { [weak self] in
            self?.updateItems()
        }
        editor.modalPresentationStyle = .overFullScreen
        editor.modalTransitionStyle = .crossDissolve
        present(editor, animated: true)
    }

    private func updateItems() {
        itemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        session.draft.itemIDs.enumerated().forEach { index, id in
            guard let item = repository.item(id: id) else { return }
            let chip = ItemArchiveChipControl(item: item, index: index)
            chip.addAction(UIAction { [weak self] _ in
                self?.presentItemEditor(itemID: id)
            }, for: .touchUpInside)
            itemsStack.addArrangedSubview(chip)
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == PublishStyle.muted {
            textView.text = ""
            textView.textColor = .black
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > 500 {
            textView.text = String(textView.text.prefix(500))
        }
        countLabel.text = "\(textView.text.count)/500"
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "Content:Please enter..."
            textView.textColor = PublishStyle.muted
        }
    }

    private func publish() {
        session.draft.title = titleField.text ?? ""
        session.draft.body = bodyView.textColor == PublishStyle.muted ? "" : bodyView.text
        session.draft.category = selectedCategory
        do {
            _ = try repository.publish(session.draft)
            clearTemporaryVideo()
            closeAfterPublishing()
        } catch {
            showMessage("Check your post", message: error.localizedDescription)
        }
    }

    private func closeAfterPublishing() {
        if let navigationController, navigationController.presentingViewController != nil {
            navigationController.dismiss(animated: true)
        } else if presentingViewController != nil {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    private func askToClose() {
        let body = bodyView.textColor == PublishStyle.muted ? "" : bodyView.text
        let dirty = session.draft.photoCount > 0 || session.draft.videoURL != nil ||
            !(titleField.text ?? "").isEmpty || !(body ?? "").isEmpty || !session.draft.itemIDs.isEmpty
        if !dirty { dismiss(animated: true); return }
        confirm(title: "Discard changes?", message: "Your unpublished post will be lost.", actionTitle: "Discard", destructive: true) { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}

private final class ItemPhotoCell: UIView {
    let removeButton = UIButton(type: .system)
    init(upload: Bool, image selectedImage: UIImage? = nil) {
        super.init(frame: .zero)
        backgroundColor = PublishStyle.panel
        layer.cornerRadius = 34
        clipsToBounds = true
        if upload {
            let icon = UIImageView(image: UIImage(systemName: "photo.badge.plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)))
            icon.tintColor = .black
            icon.contentMode = .scaleAspectFit
            let label = UILabel.publishLabel("Upload Photos", size: 12, weight: .bold)
            label.textAlignment = .center
            addSubview(icon)
            addSubview(label)
            icon.snp.makeConstraints {
                $0.top.equalToSuperview().offset(35)
                $0.centerX.equalToSuperview()
                $0.size.equalTo(45)
            }
            label.snp.makeConstraints {
                $0.top.equalTo(icon.snp.bottom).offset(12)
                $0.centerX.equalToSuperview()
                $0.width.equalTo(110)
            }
        } else {
            let image = UIImageView(image: selectedImage)
            image.contentMode = .scaleAspectFit
            addSubview(image)
            image.snp.makeConstraints { $0.edges.equalToSuperview().inset(18) }
            removeButton.tintColor = PublishStyle.pink
            removeButton.setImage(UIImage(systemName: "minus.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 23, weight: .bold)), for: .normal)
            addSubview(removeButton)
            removeButton.snp.makeConstraints {
                $0.top.trailing.equalToSuperview().inset(8)
                $0.size.equalTo(27)
            }
        }
    }
    required init?(coder: NSCoder) { nil }
}

final class ItemEditorViewController: KavoViewController {
    var onSaved: (() -> Void)?
    private let session: PublishSession
    private let dim = UIView()
    private let card = UIView()
    private let photoScroll = UIScrollView()
    private let photoStack = UIStackView()
    private let nameField = PublishTextField(placeholder: "Item Name*", size: 17)
    private let materialField = PublishTextField(placeholder: "Material*", size: 17)
    private let purchaseField = PublishTextField(placeholder: "Purchasing Channels", size: 16)
    private let careField = PublishMultilineField(placeholder: "Care Methods", size: 16)
    private let noteField = PublishMultilineField(placeholder: "Note", size: 16)
    private var editingItem: ItemArchive?
    private var photoCount: Int
    private var selectedPhotos: [UIImage] = []
    private let imagePicker = KavoImagePickerCoordinator()

    init(session: PublishSession, itemID: UUID? = nil) {
        self.session = session
        editingItem = itemID.flatMap { MockRepository.shared.item(id: $0) }
        let storedItemPhotos = editingItem?.imageDataList ?? []
        if !storedItemPhotos.isEmpty {
            selectedPhotos = storedItemPhotos.compactMap(UIImage.init(data:))
        } else if let data = editingItem?.imageData, let image = UIImage(data: data) {
            selectedPhotos = [image]
        }
        photoCount = selectedPhotos.count
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        buildBackdrop()
        buildCard()
        populate()
        imagePicker.onImagesPicked = { [weak self] images in
            guard let self else { return }
            let available = max(0, 9 - selectedPhotos.count)
            selectedPhotos.append(contentsOf: images.prefix(available))
            photoCount = max(photoCount, selectedPhotos.count)
            rebuildPhotos()
            let targetX = max(0, CGFloat(photoCount - 1) * 153)
            photoScroll.setContentOffset(CGPoint(x: targetX, y: 0), animated: true)
        }
    }

    private func buildBackdrop() {
        view.backgroundColor = PublishStyle.background
        let stage = MediaStageView()
        stage.isUserInteractionEnabled = false
        view.addSubview(stage)
        stage.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(19)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(238)
        }
        let close = UIImageView(image: UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 23, weight: .bold)))
        close.tintColor = .black
        view.addSubview(close)
        close.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(35)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.size.equalTo(24)
        }
        dim.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.addSubview(dim)
        dim.snp.makeConstraints { $0.edges.equalToSuperview() }
        dim.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeEditor)))
    }

    private func buildCard() {
        card.backgroundColor = PublishStyle.background
        card.layer.cornerRadius = 31
        card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.clipsToBounds = true
        view.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalToSuperview().offset(178)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        photoScroll.showsHorizontalScrollIndicator = false
        card.addSubview(photoScroll)
        photoScroll.snp.makeConstraints {
            $0.top.equalToSuperview().offset(31)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(140)
        }
        photoStack.axis = .horizontal
        photoStack.spacing = 18
        photoStack.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        photoStack.isLayoutMarginsRelativeArrangement = true
        photoScroll.addSubview(photoStack)
        photoStack.snp.makeConstraints {
            $0.edges.equalTo(photoScroll.contentLayoutGuide)
            $0.height.equalTo(photoScroll.frameLayoutGuide)
        }
        rebuildPhotos()

        let fields = [nameField, materialField, purchaseField, careField, noteField]
        fields.forEach(card.addSubview)
        nameField.snp.makeConstraints {
            $0.top.equalTo(photoScroll.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(47)
        }
        materialField.snp.makeConstraints {
            $0.top.equalTo(nameField.snp.bottom)
            $0.leading.trailing.height.equalTo(nameField)
        }
        purchaseField.snp.makeConstraints {
            $0.top.equalTo(materialField.snp.bottom)
            $0.leading.trailing.height.equalTo(nameField)
        }
        careField.snp.makeConstraints {
            $0.top.equalTo(purchaseField.snp.bottom)
            $0.leading.trailing.equalTo(nameField)
            $0.height.equalTo(96)
        }
        noteField.snp.makeConstraints {
            $0.top.equalTo(careField.snp.bottom)
            $0.leading.trailing.equalTo(nameField)
            $0.height.equalTo(73)
        }
        [nameField, materialField, purchaseField, careField].forEach { field in
            let line = UIView()
            line.backgroundColor = PublishStyle.line
            card.addSubview(line)
            line.snp.makeConstraints {
                $0.top.equalTo(field.snp.bottom)
                $0.leading.trailing.equalToSuperview().inset(24)
                $0.height.equalTo(1)
            }
        }

        let save = UIButton(type: .system)
        save.setTitle("Save", for: .normal)
        save.setTitleColor(.black, for: .normal)
        save.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        save.backgroundColor = .white
        save.layer.cornerRadius = 20
        save.layer.borderWidth = 1
        save.layer.borderColor = UIColor.black.cgColor
        save.layer.shadowColor = UIColor.black.cgColor
        save.layer.shadowOpacity = 1
        save.layer.shadowOffset = CGSize(width: 3, height: 4)
        save.layer.shadowRadius = 0
        save.addAction(UIAction { [weak self] _ in self?.save() }, for: .touchUpInside)
        card.addSubview(save)
        save.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(6)
            $0.height.equalTo(67)
        }
    }

    private func rebuildPhotos() {
        photoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for index in 0..<photoCount {
            let image = selectedPhotos.indices.contains(index) ? selectedPhotos[index] : nil
            let cell = ItemPhotoCell(upload: false, image: image)
            cell.tag = index
            cell.removeButton.addAction(UIAction { [weak self] _ in
                guard let self, photoCount > 0 else { return }
                if selectedPhotos.indices.contains(index) {
                    selectedPhotos.remove(at: index)
                }
                photoCount -= 1
                rebuildPhotos()
            }, for: .touchUpInside)
            cell.snp.makeConstraints { $0.width.equalTo(140) }
            photoStack.addArrangedSubview(cell)
        }
        let upload = ItemPhotoCell(upload: true)
        upload.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addPhoto)))
        upload.snp.makeConstraints { $0.width.equalTo(140) }
        photoStack.addArrangedSubview(upload)
    }

    @objc private func addPhoto() {
        guard photoCount < 9 else { return }
        imagePicker.presentSourceSheet(from: self, sourceView: photoScroll, selectionLimit: 9 - photoCount)
    }

    private func populate() {
        guard let item = editingItem else { return }
        nameField.text = item.name
        materialField.text = item.material
        purchaseField.text = item.purchasingChannels
        careField.setValue(item.careMethods)
        noteField.setValue(item.notes)
        [nameField, materialField, purchaseField].forEach {
            $0.font = .systemFont(ofSize: 16, weight: .bold)
        }
        careField.font = .systemFont(ofSize: 16, weight: .bold)
        noteField.font = .systemFont(ofSize: 16, weight: .bold)
    }

    private func save() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let enteredMaterial = materialField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let material = enteredMaterial.isEmpty ? (editingItem?.material ?? "") : enteredMaterial
        guard !name.isEmpty, !material.isEmpty else {
            showMessage("Required fields", message: "Enter Item Name and Material.")
            return
        }
        var item = editingItem ?? ItemArchive(
            id: UUID(),
            name: "",
            material: "",
            purchasingChannels: "",
            careMethods: "",
            notes: "",
            isFavorite: false
        )
        item.name = name
        item.material = material
        item.purchasingChannels = purchaseField.text ?? ""
        item.careMethods = careField.text
        item.notes = noteField.text
        item.imageData = selectedPhotos.first?.jpegData(compressionQuality: 0.82)
        item.imageDataList = selectedPhotos.compactMap { $0.jpegData(compressionQuality: 0.82) }
        repository.saveItem(item)
        if !session.draft.itemIDs.contains(item.id) {
            try? repository.link(itemID: item.id, to: &session.draft)
        }
        onSaved?()
        dismissOrPop()
    }

    @objc private func closeEditor() {
        dismissOrPop()
    }

    private func dismissOrPop() {
        if presentingViewController != nil {
            dismiss(animated: true)
        } else if navigationController?.viewControllers.first !== self {
            navigationController?.popViewController(animated: true)
        }
    }
}

final class ExistingItemsViewController: KavoViewController {
    private let session: PublishSession
    init(session: PublishSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }
}

final class ItemFormViewController: KavoViewController {
    init(item: ItemArchive?, onSave: @escaping (ItemArchive) -> Void) {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }
}
