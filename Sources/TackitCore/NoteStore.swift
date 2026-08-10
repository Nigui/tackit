import Foundation

public final class NoteStore {
    public let rootURL: URL
    private let fileManager = FileManager.default

    public init(rootURL: URL) throws {
        self.rootURL = rootURL
        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    public static func defaultRootURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return base.appendingPathComponent("Tackit/Notes", isDirectory: true)
    }

    public func fileURL(for id: UUID) -> URL {
        rootURL.appendingPathComponent("\(id.uuidString).md")
    }

    public func assetsURL(for id: UUID) -> URL {
        rootURL.appendingPathComponent("\(id.uuidString).assets", isDirectory: true)
    }

    public func save(_ note: Note) throws {
        let text = try NoteDocument.serialize(note)
        try Data(text.utf8).write(to: fileURL(for: note.id), options: .atomic)
    }

    public func load(id: UUID) throws -> Note {
        let data = try Data(contentsOf: fileURL(for: id))
        let parsed = try NoteDocument.parse(String(decoding: data, as: UTF8.self))
        return Note(id: id, metadata: parsed.metadata, body: parsed.body)
    }

    public func delete(id: UUID) throws {
        let file = fileURL(for: id)
        if fileManager.fileExists(atPath: file.path) {
            try fileManager.removeItem(at: file)
        }
        let assets = assetsURL(for: id)
        if fileManager.fileExists(atPath: assets.path) {
            try fileManager.removeItem(at: assets)
        }
    }

    public func loadAll() throws -> [Note] {
        let contents = try fileManager.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: nil
        )
        return contents.filter { $0.pathExtension == "md" }.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let parsed = try? NoteDocument.parse(String(decoding: data, as: UTF8.self)) else {
                return nil
            }
            let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent) ?? parsed.id
            return Note(id: id, metadata: parsed.metadata, body: parsed.body)
        }
    }
}
