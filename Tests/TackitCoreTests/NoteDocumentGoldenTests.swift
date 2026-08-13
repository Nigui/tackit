import XCTest
@testable import TackitCore

final class NoteDocumentGoldenTests: XCTestCase {
    private let iso: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private func fixedNote() -> Note {
        Note(
            id: UUID(uuidString: "11111111-2222-4333-8444-555566667777")!,
            metadata: NoteMetadata(
                title: "Golden: title",
                description: "a description",
                icon: "📝",
                group: "work",
                tags: ["alpha", "beta"],
                createdAt: iso.date(from: "2026-08-10T09:00:00.000Z")!,
                updatedAt: iso.date(from: "2026-08-10T09:30:15.250Z")!
            ),
            body: "# Heading\n\nSome **bold** body.\n\n---\n\nAfter a rule.\n"
        )
    }

    func testSerializeParseSerializeIsByteStable() throws {
        let once = try NoteDocument.serialize(fixedNote())
        let twice = try NoteDocument.serialize(NoteDocument.parse(once))
        XCTAssertEqual(once, twice)
    }

    func testMalformedFrontmatterThrows() {
        let content = "---\ntitle: x\nnever closed, straight into body"
        XCTAssertThrowsError(try NoteDocument.parse(content))
    }

    func testInvalidYamlFrontmatterThrows() {
        let content = "---\ntitle: [unterminated\n---\nbody"
        XCTAssertThrowsError(try NoteDocument.parse(content))
    }

    func testNilGroupRoundTrips() throws {
        let note = Note(metadata: NoteMetadata(title: "x", group: nil), body: "b")
        let parsed = try NoteDocument.parse(try NoteDocument.serialize(note))
        XCTAssertNil(parsed.metadata.group)
    }

    func testParsesTimestampsWithoutFractionalSeconds() throws {
        let content = """
        ---
        id: 11111111-2222-4333-8444-555566667777
        title: x
        description: ""
        icon: "📝"
        tags: []
        created: "2024-01-01T09:00:00Z"
        updated: "2024-01-01T09:30:00Z"
        ---
        body
        """
        let note = try NoteDocument.parse(content)
        let expected = ISO8601DateFormatter().date(from: "2024-01-01T09:00:00Z")!
        XCTAssertEqual(note.metadata.createdAt.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 0.001)
    }

    func testBodyWithRulesAndDelimitersPreserved() throws {
        let body = "before\n\n---\n\nafter\n\ninline --- dashes and a final line"
        let note = Note(metadata: NoteMetadata(title: "x"), body: body)
        let parsed = try NoteDocument.parse(try NoteDocument.serialize(note))
        XCTAssertEqual(parsed.body, body)
    }
}
