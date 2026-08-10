import XCTest
@testable import TackitCore

final class NoteStoreTests: XCTestCase {
    private func makeStore() throws -> NoteStore {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("tackit-tests-" + UUID().uuidString, isDirectory: true)
        return try NoteStore(rootURL: dir)
    }

    func testSaveLoadRoundTrip() throws {
        let store = try makeStore()
        let note = Note(metadata: NoteMetadata(title: "hello"), body: "world")
        try store.save(note)
        let loaded = try store.load(id: note.id)
        XCTAssertEqual(loaded.id, note.id)
        XCTAssertEqual(loaded.metadata.title, "hello")
        XCTAssertEqual(loaded.body, "world")
    }

    func testLoadAllAndDelete() throws {
        let store = try makeStore()
        let a = Note(metadata: NoteMetadata(title: "a"))
        let b = Note(metadata: NoteMetadata(title: "b"))
        try store.save(a)
        try store.save(b)
        XCTAssertEqual(try store.loadAll().count, 2)
        try store.delete(id: a.id)
        let all = try store.loadAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, b.id)
    }

    func testSaveOverwrites() throws {
        let store = try makeStore()
        let id = UUID()
        try store.save(Note(id: id, metadata: NoteMetadata(title: "v1"), body: "one"))
        try store.save(Note(id: id, metadata: NoteMetadata(title: "v2"), body: "two"))
        let loaded = try store.load(id: id)
        XCTAssertEqual(loaded.metadata.title, "v2")
        XCTAssertEqual(loaded.body, "two")
        XCTAssertEqual(try store.loadAll().count, 1)
    }

    func testFilesAreReadableMarkdown() throws {
        let store = try makeStore()
        let note = Note(metadata: NoteMetadata(title: "t"), body: "# Body")
        try store.save(note)
        let text = try String(contentsOf: store.fileURL(for: note.id), encoding: .utf8)
        XCTAssertTrue(text.hasPrefix("---\n"))
        XCTAssertTrue(text.contains("# Body"))
    }
}
