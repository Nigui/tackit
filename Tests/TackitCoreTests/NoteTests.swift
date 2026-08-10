import XCTest
@testable import TackitCore

final class NoteTests: XCTestCase {
    func testDefaults() {
        let note = Note(title: "hello")
        XCTAssertEqual(note.title, "hello")
        XCTAssertTrue(note.body.isEmpty)
    }

    func testCodableRoundTrip() throws {
        let note = Note(title: "a", body: "b")
        let data = try JSONEncoder().encode(note)
        let decoded = try JSONDecoder().decode(Note.self, from: data)
        XCTAssertEqual(note, decoded)
    }
}
