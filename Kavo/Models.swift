import Foundation

enum RelationshipState: String, Codable {
    case none, following, followedBy, mutual, blocked
}

struct User: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var bio: String
    var relationship: RelationshipState
    var followers: Int
    var following: Int
    var likes: Int
    var birthday: String = ""
    var location: String = ""
    var gender: String = ""
    var avatarName: String? = nil
}

struct ItemArchive: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var material: String
    var purchasingChannels: String
    var careMethods: String
    var notes: String
    var isFavorite: Bool
    var imageName: String? = nil
    var imageData: Data? = nil
    var imageDataList: [Data]? = nil
}

struct Comment: Identifiable, Equatable, Codable {
    let id: UUID
    let authorID: UUID
    var authorName: String
    var body: String
    let createdAt: Date
}

struct Post: Identifiable, Equatable, Codable {
    let id: UUID
    let authorID: UUID
    var authorName: String
    var title: String
    var body: String
    var yearsWorn: Int
    var category: String
    var isLiked: Bool
    var isSaved: Bool
    var likeCount: Int
    var comments: [Comment]
    var itemIDs: [UUID]
    var unlockPrice: Int
    var isUnlocked: Bool
    var imageNames: [String] = []
    var imageDataList: [Data]? = nil
    var videoName: String? = nil
    var videoLocalFileName: String? = nil
    var videoThumbnailData: Data? = nil
    var likedByUserIDs: [UUID]? = nil
}

enum MessageKind: Equatable, Codable {
    case text(String)
    case image(localPath: String?)
    case voice(seconds: Int, localPath: String?)
}

enum DeliveryState: String, Codable {
    case sending, sent, failed
}

struct ChatMessage: Identifiable, Equatable, Codable {
    let id: UUID
    let peerID: UUID
    let senderID: UUID
    var kind: MessageKind
    var delivery: DeliveryState
    let sentAt: Date
}

struct PublishDraft: Equatable {
    var photoCount = 0
    var photoData: [Data] = []
    var videoURL: URL? = nil
    var videoThumbnailData: Data? = nil
    var yearsWorn = 3
    var title = ""
    var body = ""
    var itemIDs: [UUID] = []
    var category: String?
}

enum RepositoryError: LocalizedError, Equatable {
    case insufficientCoins
    case invalidDraft(String)
    case duplicateItem
    case notMutual
    case blocked

    var errorDescription: String? {
        switch self {
        case .insufficientCoins: return "You don't have enough coins."
        case .invalidDraft(let reason): return reason
        case .duplicateItem: return "This item is already linked."
        case .notMutual: return "Follow each other to start chatting."
        case .blocked: return "This action is unavailable."
        }
    }
}
