import XCTest
@testable import TackitCore

final class SearchIndexTests: XCTestCase {
    private func note(_ title: String, _ body: String, tags: [String] = [], updated: Date = Date()) -> Note {
        Note(metadata: NoteMetadata(title: title, tags: tags, updatedAt: updated), body: body)
    }

    func testFindsByTitleAndBody() {
        let index = InMemorySearchIndex()
        let a = note("Groceries", "milk and eggs")
        let b = note("Ideas", "buy milk tomorrow")
        index.rebuild(from: [a, b])

        let results = index.search("milk", limit: 10)
        XCTAssertEqual(Set(results.map { $0.noteId }), Set([a.id, b.id]))
    }

    func testTitleRanksAboveBody() {
        let index = InMemorySearchIndex()
        let titleHit = note("Project Alpha", "unrelated body")
        let bodyHit = note("Untitled note", "mentions alpha once")
        index.rebuild(from: [bodyHit, titleHit])

        let results = index.search("alpha", limit: 10)
        XCTAssertEqual(results.first?.noteId, titleHit.id)
    }

    func testEmptyQueryReturnsRecentFirst() {
        let index = InMemorySearchIndex()
        let old = note("Old", "x", updated: Date(timeIntervalSince1970: 1000))
        let new = note("New", "y", updated: Date(timeIntervalSince1970: 2000))
        index.rebuild(from: [old, new])

        let results = index.search("", limit: 10)
        XCTAssertEqual(results.first?.noteId, new.id)
        XCTAssertEqual(results.count, 2)
    }

    func testUpsertAndRemove() {
        let index = InMemorySearchIndex()
        let a = note("Alpha", "body")
        index.rebuild(from: [a])
        XCTAssertEqual(index.search("alpha", limit: 10).count, 1)
        index.remove(id: a.id)
        XCTAssertEqual(index.search("alpha", limit: 10).count, 0)
    }

    func testDisplayTitleUsesSharedFallbackForTitlelessNote() {
        let index = InMemorySearchIndex()
        let n = note("", "# My heading\n\nrest of body")
        index.rebuild(from: [n])
        let result = index.search("heading", limit: 10).first
        XCTAssertEqual(result?.title, NoteDisplay.title(for: n))
    }

    func testSearchIgnoresDiacritics() {
        let index = InMemorySearchIndex()
        let n = note("Réunion", "à la café")
        index.rebuild(from: [n])
        XCTAssertEqual(index.search("reunion", limit: 10).first?.noteId, n.id)
        XCTAssertEqual(index.search("cafe", limit: 10).first?.noteId, n.id)
    }
}
