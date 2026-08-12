import XCTest
@testable import TackitCore

final class NoteStoreRobustnessTests: XCTestCase {
    private func makeStore() throws -> NoteStore {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("tackit-tests-" + UUID().uuidString, isDirectory: true)
        return try NoteStore(rootURL: dir)
    }

    func testSaveLeavesNoTempOrPartialFiles() throws {
        let store = try makeStore()
        try store.save(Note(metadata: NoteMetadata(title: "x"), body: "y"))
        let files = try FileManager.default.contentsOfDirectory(atPath: store.rootURL.path)
        XCTAssertEqual(files.count, 1)
        XCTAssertTrue(files.allSatisfy { $0.hasSuffix(".md") }, "unexpected leftover files: \(files)")
    }

    func testLoadAllSkipsCorruptFiles() throws {
        let store = try makeStore()
        let good = Note(metadata: NoteMetadata(title: "good"), body: "ok")
        try store.save(good)

        let corrupt = store.rootURL.appendingPathComponent("\(UUID().uuidString).md")
        try "---\nnot a real: [frontmatter".write(to: corrupt, atomically: true, encoding: .utf8)

        let all = try store.loadAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.metadata.title, "good")
    }

    func testFileURLMatchesSavedLocation() throws {
        let store = try makeStore()
        let note = Note(metadata: NoteMetadata(title: "x"), body: "y")
        try store.save(note)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.fileURL(for: note.id).path))
    }

    func testDeleteRemovesFileAndAssets() throws {
        let store = try makeStore()
        let note = Note(metadata: NoteMetadata(title: "x"), body: "y")
        try store.save(note)
        try FileManager.default.createDirectory(at: store.assetsURL(for: note.id), withIntermediateDirectories: true)
        try store.delete(id: note.id)
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL(for: note.id).path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.assetsURL(for: note.id).path))
    }
}
