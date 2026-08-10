import Foundation

public struct NoteMetadata: Codable, Sendable, Equatable {
    public var title: String
    public var description: String
    public var icon: String
    public var group: String?
    public var tags: [String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        title: String = "",
        description: String = "",
        icon: String = "📝",
        group: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.group = group
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Note: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var metadata: NoteMetadata
    public var body: String

    public init(id: UUID = UUID(), metadata: NoteMetadata = NoteMetadata(), body: String = "") {
        self.id = id
        self.metadata = metadata
        self.body = body
    }
}
