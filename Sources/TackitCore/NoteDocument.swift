import Foundation
import Yams

public enum NoteDocumentError: Error {
    case malformedFrontmatter
}

public enum NoteDocument {
    private struct Frontmatter: Codable {
        var id: String
        var title: String
        var description: String
        var icon: String
        var group: String?
        var tags: [String]
        var created: String
        var updated: String
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    public static func serialize(_ note: Note) throws -> String {
        let frontmatter = Frontmatter(
            id: note.id.uuidString,
            title: note.metadata.title,
            description: note.metadata.description,
            icon: note.metadata.icon,
            group: note.metadata.group,
            tags: note.metadata.tags,
            created: isoFormatter.string(from: note.metadata.createdAt),
            updated: isoFormatter.string(from: note.metadata.updatedAt)
        )
        var yaml = try YAMLEncoder().encode(frontmatter)
        if !yaml.hasSuffix("\n") { yaml += "\n" }
        return "---\n" + yaml + "---\n" + note.body
    }

    public static func parse(_ content: String) throws -> Note {
        guard content.hasPrefix("---\n") else {
            return Note(body: content)
        }
        let afterOpening = content.index(content.startIndex, offsetBy: 4)
        let rest = content[afterOpening...]
        guard let closing = rest.range(of: "\n---\n") ?? rest.range(of: "\n---") else {
            throw NoteDocumentError.malformedFrontmatter
        }
        let yamlPart = String(rest[..<closing.lowerBound])
        let body = String(rest[closing.upperBound...])
        let frontmatter = try YAMLDecoder().decode(Frontmatter.self, from: yamlPart)

        let metadata = NoteMetadata(
            title: frontmatter.title,
            description: frontmatter.description,
            icon: frontmatter.icon,
            group: frontmatter.group,
            tags: frontmatter.tags,
            createdAt: isoFormatter.date(from: frontmatter.created) ?? Date(),
            updatedAt: isoFormatter.date(from: frontmatter.updated) ?? Date()
        )
        return Note(id: UUID(uuidString: frontmatter.id) ?? UUID(), metadata: metadata, body: body)
    }
}
