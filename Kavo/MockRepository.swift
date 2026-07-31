import Foundation

protocol WalletServicing {
    var balance: Int { get }
    func recharge(coins: Int)
    func unlock(postID: UUID) throws
}

final class MockRepository: WalletServicing {
    private(set) static var shared = MockRepository()
    static let changed = Notification.Name("KavoRepositoryChanged")
    private static let currentUserKey = "Kavo.Profile.CurrentUser"
    private static let currentUserAvatarKey = "Kavo.Profile.Avatar"
    private static let chatMessagesFileName = "chat-messages.json"
    private static let chatMediaDirectoryName = "ChatMedia"
    private static let postMediaDirectoryName = "PostMedia"
    private static let seedVersionKey = "Kavo.InitialData.Version"
    private static let seedVersion = 2
    private static let primaryFollowerSeedVersion = 2
    private static let zeroInitialBalanceMigrationVersion = 1
    private static let legacyItemIDs: Set<UUID> = [
        UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
        UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
    ]

    private(set) var currentUser: User
    private(set) var currentUserAvatarData: Data?
    private(set) var users: [User]
    private(set) var posts: [Post]
    private(set) var items: [ItemArchive]
    private(set) var messages: [ChatMessage]
    private(set) var balance: Int
    private var unlockedPostIDs: Set<UUID> = []
    private var initiallyUnlockedPostIDs: Set<UUID> = []
    private var likedPostIDs: Set<UUID> = []
    private var initiallyLikedPostIDs: Set<UUID> = []
    private(set) var blockedUserIDs: Set<UUID> = []

    var visibleUsers: [User] {
        users.filter { !blockedUserIDs.contains($0.id) }
    }

    var visiblePosts: [Post] {
        posts
            .filter { !blockedUserIDs.contains($0.authorID) }
            .map(sanitizedPost)
    }

    static func reloadSharedForCurrentAccount() {
        shared = MockRepository()
    }

    func deleteCurrentAccountData() throws {
        let accountIdentifier = AuthSessionStore.accountIdentifier
        let defaults = UserDefaults.standard
        let accountKeys = [
            "Kavo.Unlocks.\(accountIdentifier)",
            "Kavo.LikedPosts.\(accountIdentifier)",
            "Kavo.PublishedPosts.\(accountIdentifier)",
            "Kavo.Balance.\(accountIdentifier)",
            "Kavo.Balance.ZeroInitialMigration.\(accountIdentifier)",
            "Kavo.Relationships.\(accountIdentifier)",
            "Kavo.ItemArchives.\(accountIdentifier)",
            "Kavo.InitialFollowers.Version.\(accountIdentifier)",
            "Kavo.IAP.ProcessedTransactions.\(accountIdentifier)"
        ]

        let fileManager = FileManager.default
        let chatMessagesURL = try Self.chatMessagesURL()
        let chatMediaURL = try Self.applicationSupportDirectory()
            .appendingPathComponent(Self.chatMediaDirectoryName, isDirectory: true)
        let postMediaURL = try Self.applicationSupportDirectory()
            .appendingPathComponent(Self.postMediaDirectoryName, isDirectory: true)

        for url in [chatMessagesURL, chatMediaURL, postMediaURL]
        where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }

        accountKeys.forEach { defaults.removeObject(forKey: $0) }
        defaults.removeObject(forKey: Self.currentUserKey)
        defaults.removeObject(forKey: Self.currentUserAvatarKey)
    }

    init(balance: Int = 0) {
        let meID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let defaultUser = User(id: meID, name: "Mia", bio: "Fade, style & share.", relationship: .none, followers: 236, following: 86, likes: 1_920)
        if let data = UserDefaults.standard.data(forKey: Self.currentUserKey),
           let savedUser = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = savedUser
        } else {
            currentUser = defaultUser
        }
        currentUserAvatarData = UserDefaults.standard.data(forKey: Self.currentUserAvatarKey)
        let initialData = Self.makeInitialData()
        users = initialData.users
        items = initialData.items
        posts = initialData.posts
        Self.migratePrimaryFollowerSeedIfNeeded(
            accountIdentifier: AuthSessionStore.accountIdentifier,
            followerIDs: Array(users.prefix(2).map(\.id))
        )
        let validPeerIDs = Set(users.map(\.id))
        messages = (Self.loadChatMessages() ?? []).filter { validPeerIDs.contains($0.peerID) }
        let accountIdentifier = AuthSessionStore.accountIdentifier
        let balanceStorageKey = "Kavo.Balance.\(accountIdentifier)"
        let balanceMigrationKey = "Kavo.Balance.ZeroInitialMigration.\(accountIdentifier)"
        if UserDefaults.standard.object(forKey: balanceStorageKey) != nil {
            let storedBalance = UserDefaults.standard.integer(forKey: balanceStorageKey)
            if UserDefaults.standard.integer(forKey: balanceMigrationKey) <
                Self.zeroInitialBalanceMigrationVersion,
               storedBalance == 420 {
                self.balance = 0
                UserDefaults.standard.set(0, forKey: balanceStorageKey)
            } else {
                self.balance = storedBalance
            }
        } else {
            self.balance = balance
        }
        UserDefaults.standard.set(
            Self.zeroInitialBalanceMigrationVersion,
            forKey: balanceMigrationKey
        )
        if let storedRelationships = UserDefaults.standard.dictionary(forKey: relationshipStorageKey) as? [String: String] {
            for index in users.indices {
                if let rawValue = storedRelationships[users[index].id.uuidString],
                   let relationship = RelationshipState(rawValue: rawValue) {
                    users[index].relationship = relationship
                    if relationship == .blocked {
                        blockedUserIDs.insert(users[index].id)
                    }
                }
            }
        }
        synchronizeUserRelationshipCounts()
        if let data = UserDefaults.standard.data(forKey: itemStorageKey),
           let storedItems = try? JSONDecoder().decode([ItemArchive].self, from: data) {
            for item in storedItems where !Self.legacyItemIDs.contains(item.id) {
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    items[index] = item
                } else {
                    items.append(item)
                }
            }
        }
        if let data = UserDefaults.standard.data(forKey: publishedPostsStorageKey),
           let publishedPosts = try? JSONDecoder().decode([Post].self, from: data) {
            posts.insert(contentsOf: publishedPosts.filter { savedPost in
                !posts.contains(where: { $0.id == savedPost.id })
            }, at: 0)
        }
        initiallyUnlockedPostIDs = Set(posts.filter(\.isUnlocked).map(\.id))
        unlockedPostIDs = initiallyUnlockedPostIDs
        initiallyLikedPostIDs = Set(posts.filter(\.isLiked).map(\.id))
        likedPostIDs = initiallyLikedPostIDs
        reloadAccountState(notifyChanges: false)
        migrateInitialDataIfNeeded()
    }

    private static func migratePrimaryFollowerSeedIfNeeded(
        accountIdentifier: String,
        followerIDs: [UUID]
    ) {
        let account = accountIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard account == "123@gmail.com" else { return }
        let versionKey = "Kavo.InitialFollowers.Version.\(account)"
        guard UserDefaults.standard.integer(forKey: versionKey) < primaryFollowerSeedVersion else {
            return
        }
        let relationshipKey = "Kavo.Relationships.\(account)"
        var storedRelationships = UserDefaults.standard.dictionary(forKey: relationshipKey) as? [String: String] ?? [:]
        followerIDs.forEach { storedRelationships.removeValue(forKey: $0.uuidString) }
        UserDefaults.standard.set(storedRelationships, forKey: relationshipKey)
        UserDefaults.standard.set(primaryFollowerSeedVersion, forKey: versionKey)
    }

    private static func makeInitialData() -> (users: [User], items: [ItemArchive], posts: [Post]) {
        let followsPrimaryAccount = AuthSessionStore.accountIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() == "123@gmail.com"
        let primaryAccountFollowerState: RelationshipState = followsPrimaryAccount ? .followedBy : .none
        let userIDs = (1...6).map {
            UUID(uuidString: String(format: "30000000-0000-0000-0000-%012d", $0))!
        }
        let users = [
            User(id: userIDs[0], name: "Hannah", bio: "thrifting & 90s vintage vibes", relationship: primaryAccountFollowerState, followers: 0, following: followsPrimaryAccount ? 1 : 0, likes: 0, avatarName: "1"),
            User(id: userIDs[1], name: "Lucas", bio: "just coffee, vinyls & Sunday rides", relationship: primaryAccountFollowerState, followers: 0, following: followsPrimaryAccount ? 1 : 0, likes: 0, avatarName: "4"),
            User(id: userIDs[2], name: "Sienna", bio: "living in daylight ☀️ | Film photos & everyday life", relationship: .none, followers: 0, following: 0, likes: 0, avatarName: "3"),
            User(id: userIDs[3], name: "Tyler", bio: "Skate, film, repeat.", relationship: .none, followers: 0, following: 0, likes: 0, avatarName: "5"),
            User(id: userIDs[4], name: "May", bio: "sourdough, matcha & slow living", relationship: .none, followers: 0, following: 0, likes: 0, avatarName: "6"),
            User(id: userIDs[5], name: "Joan", bio: "35mm grain & bedroom indie tunes", relationship: .none, followers: 0, following: 0, likes: 0, avatarName: "8")
        ]

        let itemIDs = (1...9).map {
            UUID(uuidString: String(format: "40000000-0000-0000-0000-%012d", $0))!
        }
        let items = [
            ItemArchive(id: itemIDs[0], name: "Mustard ribbed short-sleeve knit top", material: "65% cotton, 35% polyester ribbed knit", purchasingChannels: "", careMethods: "Machine wash cold on gentle cycle with similar colors; lay flat to dry; cool iron if needed; do not bleach.", notes: "", isFavorite: false, imageName: "download (4)"),
            ItemArchive(id: itemIDs[1], name: "High-rise flared denim jeans", material: "99% cotton, 1% elastane denim", purchasingChannels: "", careMethods: "Machine wash cold inside-out; wash with like colors only; tumble dry low; iron on reverse.", notes: "", isFavorite: false, imageName: "download (5)"),
            ItemArchive(id: itemIDs[2], name: "Classic indigo blue denim trucker jacket", material: "100% cotton denim, brass-tone metal buttons", purchasingChannels: "", careMethods: "Machine wash cold inside-out; tumble dry low; warm iron; do not bleach.", notes: "", isFavorite: false, imageName: "download (11)"),
            ItemArchive(id: itemIDs[3], name: "Brown leather work shoes", material: "Genuine leather", purchasingChannels: "", careMethods: "Brush off dirt after wear; condition with leather cream monthly; use cedar shoe trees; air dry only.", notes: "", isFavorite: false, imageName: "download (10)"),
            ItemArchive(id: itemIDs[4], name: "Red polka-dot tea dress", material: "100% cotton sateen shell", purchasingChannels: "", careMethods: "Machine wash cold gentle cycle; hang to dry; cool iron on reverse; do not bleach.", notes: "", isFavorite: false, imageName: "00"),
            ItemArchive(id: itemIDs[5], name: "White Mary Jane heels", material: "Synthetic leather", purchasingChannels: "", careMethods: "Wipe with damp cloth; apply shoe protector spray before first wear; air dry; do not machine wash.", notes: "", isFavorite: false, imageName: "download (7)"),
            ItemArchive(id: itemIDs[6], name: "Sunshine yellow graphic-print relaxed tee", material: "100% cotton", purchasingChannels: "", careMethods: "Machine wash cold inside-out with similar colors; tumble dry low; cool iron on reverse; do not bleach.", notes: "", isFavorite: false, imageName: "download (15)"),
            ItemArchive(id: itemIDs[7], name: "High-waist denim cut-off shorts", material: "100% cotton denim", purchasingChannels: "", careMethods: "Turn inside out; hand wash cold separately; line dry in shade; iron on reverse at low temperature; do not wring.", notes: "", isFavorite: false, imageName: "download (1)"),
            ItemArchive(id: itemIDs[8], name: "High-top canvas sneakers", material: "Canvas upper, rubber sole", purchasingChannels: "", careMethods: "Spot clean canvas with mild soap and soft brush; air dry; do not machine wash.", notes: "", isFavorite: false, imageName: "download (14)")
        ]

        let postIDs = (1...6).map {
            UUID(uuidString: String(format: "50000000-0000-0000-0000-%012d", $0))!
        }
        let posts = [
            Post(id: postIDs[0], authorID: userIDs[0], authorName: "Hannah", title: "Mustard Knit & Flared Denim", body: "Pulled over the Chevelle just to catch the sunset on this 70s road trip look — flared denim and a mustard knit are my desert essentials. Nothing feels better than leather boots on hot asphalt.", yearsWorn: 1, category: "Denim", isLiked: false, isSaved: false, likeCount: 0, comments: [], itemIDs: [itemIDs[0], itemIDs[1]], unlockPrice: 300, isUnlocked: false, imageNames: ["t002"]),
            Post(id: postIDs[1], authorID: userIDs[1], authorName: "Lucas", title: "Indigo Denim Jacket & Khaki Chinos", body: "Nothing beats a denim jacket, broken-in chinos, and a truck that still purrs like a kitten. Paused for golden hour before heading to the county fair.", yearsWorn: 4, category: "Workwear", isLiked: false, isSaved: false, likeCount: 0, comments: [], itemIDs: [itemIDs[2], itemIDs[3]], unlockPrice: 300, isUnlocked: false, imageNames: ["t004"]),
            Post(id: postIDs[2], authorID: userIDs[2], authorName: "Sienna", title: "Navy Shift Dress & Suede Ankle Boots", body: "Shift dress, pointed boots, and a cup of black coffee — my perfect Sunday morning uniform. The mini hemline and monochrome palette always feel like 1965.", yearsWorn: 2, category: "Denim", isLiked: false, isSaved: false, likeCount: 0, comments: [], itemIDs: [], unlockPrice: 300, isUnlocked: false, imageNames: [], videoName: "1"),
            Post(id: postIDs[3], authorID: userIDs[3], authorName: "Tyler", title: "Cuban Collar Shirt & Linen Trousers", body: "Wooden longboard under one arm, salt in my hair, and linen that already knows the ocean by heart. Life's better in board shorts and a Cuban collar.", yearsWorn: 1, category: "Biker", isLiked: false, isSaved: false, likeCount: 0, comments: [], itemIDs: [], unlockPrice: 300, isUnlocked: false, imageNames: ["t005"]),
            Post(id: postIDs[4], authorID: userIDs[4], authorName: "May", title: "Red Polka Dot Tea Dress", body: "Polka dots, red lipstick, and a milkshake with two straws — that's my kind of perfect date night. My sweetheart of a dress swishes just right when the jukebox spins.", yearsWorn: 3, category: "Ivy Style", isLiked: false, isSaved: false, likeCount: 0, comments: [], itemIDs: [itemIDs[4], itemIDs[5]], unlockPrice: 300, isUnlocked: false, imageNames: ["t003"]),
            Post(id: postIDs[5], authorID: userIDs[5], authorName: "Joan", title: "Sunshine Yellow Tee & Patchwork Denim Cutoffs", body: "Tied on my favorite graphic tee and the most decorated denim shorts in my closet — every patch and charm tells a story from last summer's flea market crawl. Peace sign, because Saturday is for thrifting, dancing, and unapologetic color.", yearsWorn: 2, category: "Denim", isLiked: false, isSaved: false, likeCount: 0, comments: [], itemIDs: [itemIDs[6], itemIDs[7], itemIDs[8]], unlockPrice: 300, isUnlocked: false, imageNames: ["t001"])
        ]
        return (users, items, posts)
    }

    private func migrateInitialDataIfNeeded() {
        guard UserDefaults.standard.integer(forKey: Self.seedVersionKey) < Self.seedVersion else { return }
        UserDefaults.standard.removeObject(forKey: relationshipStorageKey)
        UserDefaults.standard.removeObject(forKey: unlockStorageKey)
        UserDefaults.standard.removeObject(forKey: likedStorageKey)
        persistChatMessages()
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: itemStorageKey)
        }
        UserDefaults.standard.set(Self.seedVersion, forKey: Self.seedVersionKey)
    }

    private func notify() {
        NotificationCenter.default.post(name: Self.changed, object: self)
    }

    func post(id: UUID) -> Post? {
        guard let post = posts.first(where: { $0.id == id }),
              !blockedUserIDs.contains(post.authorID) else { return nil }
        return sanitizedPost(post)
    }

    func user(id: UUID) -> User? {
        if currentUser.id == id { return currentUser }
        guard !blockedUserIDs.contains(id) else { return nil }
        return users.first { $0.id == id }
    }
    func item(id: UUID) -> ItemArchive? { items.first { $0.id == id } }

    func postVideoURL(for post: Post) -> URL? {
        if let fileName = post.videoLocalFileName,
           let directory = try? Self.postMediaDirectory() {
            let url = directory.appendingPathComponent(fileName, isDirectory: false)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        guard let name = post.videoName else { return nil }
        let resource = name as NSString
        let fileExtension = resource.pathExtension.isEmpty ? "mp4" : resource.pathExtension
        let baseName = resource.deletingPathExtension
        return Bundle.main.url(forResource: baseName, withExtension: fileExtension)
    }

    func reloadAccountState() {
        reloadAccountState(notifyChanges: true)
    }

    private func reloadAccountState(notifyChanges: Bool) {
        let storedIDs = UserDefaults.standard.stringArray(forKey: unlockStorageKey)
            .flatMap { values in Set(values.compactMap(UUID.init(uuidString:))) } ?? []
        unlockedPostIDs = initiallyUnlockedPostIDs.union(storedIDs)
        for index in posts.indices {
            posts[index].isUnlocked = unlockedPostIDs.contains(posts[index].id)
        }
        if let storedValues = UserDefaults.standard.stringArray(forKey: likedStorageKey) {
            likedPostIDs = Set(storedValues.compactMap(UUID.init(uuidString:)))
        } else {
            likedPostIDs = initiallyLikedPostIDs
        }
        for index in posts.indices {
            let wasInitiallyLiked = initiallyLikedPostIDs.contains(posts[index].id)
            let isLiked = likedPostIDs.contains(posts[index].id)
            if wasInitiallyLiked != isLiked {
                posts[index].likeCount += isLiked ? 1 : -1
            }
            posts[index].isLiked = isLiked
        }
        if notifyChanges { notify() }
    }

    private var unlockStorageKey: String {
        "Kavo.Unlocks.\(AuthSessionStore.accountIdentifier)"
    }

    private var likedStorageKey: String {
        "Kavo.LikedPosts.\(AuthSessionStore.accountIdentifier)"
    }

    private var publishedPostsStorageKey: String {
        "Kavo.PublishedPosts.\(AuthSessionStore.accountIdentifier)"
    }

    private var balanceStorageKey: String {
        "Kavo.Balance.\(AuthSessionStore.accountIdentifier)"
    }

    private var relationshipStorageKey: String {
        "Kavo.Relationships.\(AuthSessionStore.accountIdentifier)"
    }

    private var itemStorageKey: String {
        "Kavo.ItemArchives.\(AuthSessionStore.accountIdentifier)"
    }

    @discardableResult
    func toggleLike(postID: UUID) -> Post? {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return nil }
        posts[index].isLiked.toggle()
        posts[index].likeCount += posts[index].isLiked ? 1 : -1
        if posts[index].isLiked {
            likedPostIDs.insert(postID)
            var likerIDs = posts[index].likedByUserIDs ?? []
            if !likerIDs.contains(currentUser.id) {
                likerIDs.append(currentUser.id)
            }
            posts[index].likedByUserIDs = likerIDs
        } else {
            likedPostIDs.remove(postID)
            posts[index].likedByUserIDs?.removeAll { $0 == currentUser.id }
        }
        UserDefaults.standard.set(likedPostIDs.map(\.uuidString), forKey: likedStorageKey)
        persistPublishedPosts()
        notify()
        return posts[index]
    }

    func addComment(postID: UUID, body: String) throws {
        let value = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 500 else { throw RepositoryError.invalidDraft("Comment must contain 1–500 characters.") }
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].comments.insert(Comment(id: UUID(), authorID: currentUser.id, authorName: currentUser.name, body: value, createdAt: Date()), at: 0)
        notify()
    }

    func recharge(coins: Int) {
        balance += coins
        UserDefaults.standard.set(balance, forKey: balanceStorageKey)
        notify()
    }

    func unlock(postID: UUID) throws {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        if unlockedPostIDs.contains(postID) || posts[index].isUnlocked { return }
        let price = posts[index].unlockPrice
        guard balance >= price else { throw RepositoryError.insufficientCoins }
        balance -= price
        UserDefaults.standard.set(balance, forKey: balanceStorageKey)
        unlockedPostIDs.insert(postID)
        posts[index].isUnlocked = true
        UserDefaults.standard.set(unlockedPostIDs.map(\.uuidString), forKey: unlockStorageKey)
        notify()
    }

    @discardableResult
    func toggleFollow(userID: UUID) -> RelationshipState? {
        guard let index = users.firstIndex(where: { $0.id == userID }) else { return nil }
        let wasFollowing = users[index].relationship == .following || users[index].relationship == .mutual
        switch users[index].relationship {
        case .none: users[index].relationship = .following
        case .following: users[index].relationship = .none
        case .followedBy: users[index].relationship = .mutual
        case .mutual: users[index].relationship = .followedBy
        case .blocked: return .blocked
        }
        let isFollowing = users[index].relationship == .following || users[index].relationship == .mutual
        if wasFollowing != isFollowing {
            currentUser.following = max(0, currentUser.following + (isFollowing ? 1 : -1))
            users[index].followers = max(0, users[index].followers + (isFollowing ? 1 : -1))
            if let data = try? JSONEncoder().encode(currentUser) {
                UserDefaults.standard.set(data, forKey: Self.currentUserKey)
            }
        }
        persistRelationships()
        notify()
        return users[index].relationship
    }

    func block(userID: UUID) {
        guard let index = users.firstIndex(where: { $0.id == userID }) else { return }
        let oldRelationship = users[index].relationship
        if oldRelationship == .following || oldRelationship == .mutual {
            currentUser.following = max(0, currentUser.following - 1)
            users[index].followers = max(0, users[index].followers - 1)
        }
        if oldRelationship == .followedBy || oldRelationship == .mutual {
            currentUser.followers = max(0, currentUser.followers - 1)
            users[index].following = max(0, users[index].following - 1)
        }
        blockedUserIDs.insert(userID)
        users[index].relationship = .blocked
        persistCurrentUser()
        persistRelationships()
        notify()
    }

    func unblock(userID: UUID) {
        blockedUserIDs.remove(userID)
        if let index = users.firstIndex(where: { $0.id == userID }) {
            users[index].relationship = .none
        }
        persistRelationships()
        notify()
    }

    func updateProfile(
        name: String,
        bio: String,
        birthday: String? = nil,
        location: String? = nil,
        gender: String? = nil,
        avatarData: Data? = nil
    ) {
        currentUser.name = name
        currentUser.bio = bio
        if let birthday { currentUser.birthday = birthday }
        if let location { currentUser.location = location }
        if let gender { currentUser.gender = gender }
        if let avatarData {
            currentUserAvatarData = avatarData
            UserDefaults.standard.set(avatarData, forKey: Self.currentUserAvatarKey)
        }
        for index in posts.indices where posts[index].authorID == currentUser.id {
            posts[index].authorName = name
        }
        persistPublishedPosts()
        if let data = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(data, forKey: Self.currentUserKey)
        }
        notify()
    }

    func saveItem(_ value: ItemArchive) {
        if let index = items.firstIndex(where: { $0.id == value.id }) {
            items[index] = value
        } else {
            items.append(value)
        }
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: itemStorageKey)
        }
        notify()
    }

    @discardableResult
    func toggleFavorite(itemID: UUID) -> ItemArchive? {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return nil }
        items[index].isFavorite.toggle()
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: itemStorageKey)
        }
        notify()
        return items[index]
    }

    func link(itemID: UUID, to draft: inout PublishDraft) throws {
        guard items.contains(where: { $0.id == itemID }) else { return }
        guard !draft.itemIDs.contains(itemID) else { throw RepositoryError.duplicateItem }
        guard draft.itemIDs.count < 10 else { throw RepositoryError.invalidDraft("A post supports up to 10 Item Archives.") }
        draft.itemIDs.append(itemID)
    }

    func unlink(itemID: UUID, from draft: inout PublishDraft) {
        draft.itemIDs.removeAll { $0 == itemID }
        // Deliberately does not remove the original from `items`.
    }

    func reorderItems(in draft: inout PublishDraft, from: Int, to: Int) {
        guard draft.itemIDs.indices.contains(from), to >= 0, to < draft.itemIDs.count else { return }
        let id = draft.itemIDs.remove(at: from)
        draft.itemIDs.insert(id, at: to)
    }

    @discardableResult
    func publish(_ draft: PublishDraft) throws -> Post {
        let hasVideo = draft.videoURL != nil
        let hasValidPhotos = (1...3).contains(draft.photoCount)
        guard hasVideo || hasValidPhotos else {
            throw RepositoryError.invalidDraft("Add 1–3 photos or one video.")
        }
        guard !(hasVideo && draft.photoCount > 0) else {
            throw RepositoryError.invalidDraft("Photos and video cannot be added to the same post.")
        }
        guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, draft.title.count <= 80 else { throw RepositoryError.invalidDraft("Title must contain 1–80 characters.") }
        guard !draft.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, draft.body.count <= 500 else { throw RepositoryError.invalidDraft("Content must contain 1–500 characters.") }
        guard (1...10).contains(draft.itemIDs.count) else { throw RepositoryError.invalidDraft("Add 1–10 Item Archives.") }
        guard let category = draft.category else { throw RepositoryError.invalidDraft("Choose a category.") }
        let videoFileName = try draft.videoURL.map(Self.storePostVideo)
        let post = Post(
            id: UUID(),
            authorID: currentUser.id,
            authorName: currentUser.name,
            title: draft.title,
            body: draft.body,
            yearsWorn: draft.yearsWorn,
            category: category,
            isLiked: false,
            isSaved: false,
            likeCount: 0,
            comments: [],
            itemIDs: draft.itemIDs,
            unlockPrice: 300,
            isUnlocked: true,
            imageNames: [],
            imageDataList: draft.photoData,
            videoLocalFileName: videoFileName,
            videoThumbnailData: draft.videoThumbnailData
        )
        posts.insert(post, at: 0)
        initiallyUnlockedPostIDs.insert(post.id)
        unlockedPostIDs.insert(post.id)
        persistPublishedPosts()
        notify()
        return post
    }

    private func persistPublishedPosts() {
        let values = posts.filter { $0.authorID == currentUser.id }
        guard let data = try? JSONEncoder().encode(values) else { return }
        UserDefaults.standard.set(data, forKey: publishedPostsStorageKey)
    }

    private func persistRelationships() {
        let values = Dictionary(uniqueKeysWithValues: users.map {
            ($0.id.uuidString, $0.relationship.rawValue)
        })
        UserDefaults.standard.set(values, forKey: relationshipStorageKey)
    }

    private func synchronizeUserRelationshipCounts() {
        for index in users.indices {
            let currentUserFollows = users[index].relationship == .following ||
                users[index].relationship == .mutual
            users[index].followers = currentUserFollows ? 1 : 0
        }
    }

    private func sanitizedPost(_ source: Post) -> Post {
        var post = source
        post.comments.removeAll { blockedUserIDs.contains($0.authorID) }
        return post
    }

    private func persistCurrentUser() {
        guard let data = try? JSONEncoder().encode(currentUser) else { return }
        UserDefaults.standard.set(data, forKey: Self.currentUserKey)
    }

    func send(_ kind: MessageKind, to userID: UUID) throws {
        guard let user = user(id: userID) else { return }
        guard user.relationship != .blocked else { throw RepositoryError.blocked }
        guard user.relationship == .mutual else { throw RepositoryError.notMutual }
        messages.append(ChatMessage(id: UUID(), peerID: userID, senderID: currentUser.id, kind: kind, delivery: .sent, sentAt: Date()))
        persistChatMessages()
        notify()
    }

    func messages(with userID: UUID) -> [ChatMessage] {
        guard !blockedUserIDs.contains(userID) else { return [] }
        return messages
            .filter { $0.peerID == userID }
            .sorted { $0.sentAt < $1.sentAt }
    }

    func storeChatImageData(_ data: Data) throws -> String {
        let resource = try makeChatMediaResource(fileExtension: "jpg")
        try data.write(to: resource.url, options: .atomic)
        return resource.fileName
    }

    func makeChatVoiceResource() throws -> (fileName: String, url: URL) {
        try makeChatMediaResource(fileExtension: "m4a")
    }

    func chatMediaURL(for fileName: String?) -> URL? {
        guard let fileName, !fileName.isEmpty,
              let directory = try? Self.chatMediaDirectory() else { return nil }
        return directory.appendingPathComponent(fileName, isDirectory: false)
    }

    func deleteChatMedia(fileName: String?) {
        guard let url = chatMediaURL(for: fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private func makeChatMediaResource(fileExtension: String) throws -> (fileName: String, url: URL) {
        let fileName = "\(UUID().uuidString).\(fileExtension)"
        let directory = try Self.chatMediaDirectory()
        return (fileName, directory.appendingPathComponent(fileName, isDirectory: false))
    }

    private static func applicationSupportDirectory() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("Kavo", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func chatMediaDirectory() throws -> URL {
        let directory = try applicationSupportDirectory().appendingPathComponent(chatMediaDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func postMediaDirectory() throws -> URL {
        let directory = try applicationSupportDirectory().appendingPathComponent(postMediaDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func storePostVideo(from sourceURL: URL) throws -> String {
        let fileExtension = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension
        let fileName = "\(UUID().uuidString).\(fileExtension)"
        let destination = try postMediaDirectory().appendingPathComponent(fileName, isDirectory: false)
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return fileName
    }

    private static func chatMessagesURL() throws -> URL {
        try applicationSupportDirectory().appendingPathComponent(chatMessagesFileName, isDirectory: false)
    }

    private static func loadChatMessages() -> [ChatMessage]? {
        guard let url = try? chatMessagesURL(),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([ChatMessage].self, from: data)
    }

    private func persistChatMessages() {
        guard let data = try? JSONEncoder().encode(messages),
              let url = try? Self.chatMessagesURL() else { return }
        try? data.write(to: url, options: .atomic)
    }
}
