import XCTest
@testable import TackitCore

final class NoteTests: XCTestCase {
    func testDefaults() {
        let note = Note(metadata: NoteMetadata(title: "hello"))
        XCTAssertEqual(note.metadata.title, "hello")
        XCTAssertEqual(note.metadata.icon, "📝")
        XCTAssertTrue(note.body.isEmpty)
    }

    func testCodableRoundTrip() throws {
        let note = Note(metadata: NoteMetadata(title: "a", group: "work", tags: ["x", "y"]), body: "b")
        let data = try JSONEncoder().encode(note)
        let decoded = try JSONDecoder().decode(Note.self, from: data)
        XCTAssertEqual(note, decoded)
    }

    func testGroupAndTagIdentity() {
        XCTAssertEqual(Group("work").id, "work")
        XCTAssertEqual(Tag("urgent").id, "urgent")
    }
}
