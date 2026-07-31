import XCTest
@testable import Kavo

final class MockRepositoryTests: XCTestCase {
    func testUnlockIsIdempotent() throws {
        let repository = MockRepository(balance: 1_000)
        let postID = repository.posts.first(where: { !$0.isUnlocked })!.id
        try repository.unlock(postID: postID)
        let chargedBalance = repository.balance
        try repository.unlock(postID: postID)
        XCTAssertEqual(repository.balance, chargedBalance)
        XCTAssertTrue(repository.post(id: postID)!.isUnlocked)
    }

    func testInsufficientBalanceDoesNotUnlockOrCharge() {
        let repository = MockRepository(balance: 10)
        let postID = repository.posts.first(where: { !$0.isUnlocked })!.id
        XCTAssertThrowsError(try repository.unlock(postID: postID)) {
            XCTAssertEqual($0 as? RepositoryError, .insufficientCoins)
        }
        XCTAssertEqual(repository.balance, 10)
        XCTAssertFalse(repository.post(id: postID)!.isUnlocked)
    }

    func testFollowAndUnfollowUpdateRelationship() {
        let repository = MockRepository()
        let target = repository.users[2]
        XCTAssertEqual(repository.toggleFollow(userID: target.id), .following)
        XCTAssertEqual(repository.toggleFollow(userID: target.id), .none)
    }

    func testInitialDataMatchesCSV() {
        let repository = MockRepository()
        let seededPosts = repository.posts.filter { $0.id.uuidString.hasPrefix("50000000") }
        XCTAssertEqual(repository.users.map(\.name), ["Hannah", "Lucas", "Sienna", "Tyler", "May", "Joan"])
        XCTAssertEqual(seededPosts.count, 6)
        XCTAssertEqual(repository.items.filter { $0.id.uuidString.hasPrefix("40000000") }.count, 9)
        XCTAssertEqual(seededPosts.map(\.category), ["Denim", "Workwear", "Denim", "Biker", "Ivy Style", "Denim"])
    }

    func testLikeAndCommentAreImmediatelyConsistent() throws {
        let repository = MockRepository()
        let post = repository.posts[0]
        let originalLikes = post.likeCount
        repository.toggleLike(postID: post.id)
        XCTAssertEqual(repository.post(id: post.id)?.likeCount, originalLikes + 1)
        try repository.addComment(postID: post.id, body: "A useful comment")
        XCTAssertEqual(repository.post(id: post.id)?.comments.first?.body, "A useful comment")
    }

    func testLinkingSecondItemDoesNotOverwriteFirst() throws {
        let repository = MockRepository()
        var draft = PublishDraft()
        try repository.link(itemID: repository.items[0].id, to: &draft)
        try repository.link(itemID: repository.items[1].id, to: &draft)
        XCTAssertEqual(draft.itemIDs, [repository.items[0].id, repository.items[1].id])
    }

    func testUnlinkOnlyRemovesPostRelationship() throws {
        let repository = MockRepository()
        let item = repository.items[0]
        var draft = PublishDraft()
        try repository.link(itemID: item.id, to: &draft)
        repository.unlink(itemID: item.id, from: &draft)
        XCTAssertFalse(draft.itemIDs.contains(item.id))
        XCTAssertEqual(repository.item(id: item.id), item)
    }

    func testPublishPreservesItemOrderAndUpdatesSharedFeed() throws {
        let repository = MockRepository()
        let ordered = [repository.items[1].id, repository.items[0].id]
        let draft = PublishDraft(photoCount: 2, yearsWorn: 3, title: "A durable rotation", body: "Everything here is worn and repaired.", itemIDs: ordered, category: "Denim")
        let published = try repository.publish(draft)
        XCTAssertEqual(published.itemIDs, ordered)
        XCTAssertEqual(repository.posts.first?.id, published.id)
        XCTAssertEqual(repository.post(id: published.id)?.authorName, repository.currentUser.name)
    }

    func testProfileChangePropagatesToOwnedPosts() throws {
        let repository = MockRepository()
        var draft = PublishDraft(photoCount: 1, yearsWorn: 2, title: "Personal archive", body: "A long enough description.", itemIDs: [repository.items[0].id], category: "Denim")
        let post = try repository.publish(draft)
        repository.updateProfile(name: "Updated Name", bio: "Updated Bio")
        XCTAssertEqual(repository.post(id: post.id)?.authorName, "Updated Name")
        draft.title = "Still valid"
    }
}
