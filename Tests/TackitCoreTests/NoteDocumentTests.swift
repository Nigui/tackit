import XCTest
@testable import TackitCore

final class NoteDocumentTests: XCTestCase {
    private let iso: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func testRoundTripPreservesEverything() throws {
        let created = iso.date(from: "2026-08-10T12:00:00.000Z")!
        let updated = iso.date(from: "2026-08-10T12:05:30.500Z")!
        let note = Note(
            metadata: NoteMetadata(
                title: "Title: with a colon",
                description: "a description",
                icon: "⚡",
                group: "work",
                tags: ["alpha", "beta"],
                createdAt: created,
                updatedAt: updated
            ),
            body: "# Heading\n\nSome **markdown** body.\n\n---\n\nText after a horizontal rule."
        )

        let text = try NoteDocument.serialize(note)
        let parsed = try NoteDocument.parse(text)

        XCTAssertEqual(parsed.id, note.id)
        XCTAssertEqual(parsed.metadata.title, note.metadata.title)
        XCTAssertEqual(parsed.metadata.description, note.metadata.description)
        XCTAssertEqual(parsed.metadata.icon, note.metadata.icon)
        XCTAssertEqual(parsed.metadata.group, note.metadata.group)
        XCTAssertEqual(parsed.metadata.tags, note.metadata.tags)
        XCTAssertEqual(parsed.metadata.createdAt, created)
        XCTAssertEqual(parsed.metadata.updatedAt, updated)
        XCTAssertEqual(parsed.body, note.body)
    }

    func testContentWithoutFrontmatterIsTreatedAsBody() throws {
        let parsed = try NoteDocument.parse("just some body text")
        XCTAssertEqual(parsed.body, "just some body text")
        XCTAssertTrue(parsed.metadata.title.isEmpty)
    }

    func testStartsWithFrontmatterDelimiter() throws {
        let note = Note(metadata: NoteMetadata(title: "x"), body: "y")
        let text = try NoteDocument.serialize(note)
        XCTAssertTrue(text.hasPrefix("---\n"))
    }
}
