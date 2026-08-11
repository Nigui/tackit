import Foundation

public enum NoteDisplay {
    public static func title(for note: Note) -> String {
        note.metadata.title.isEmpty ? dateFormatter.string(from: note.metadata.createdAt) : note.metadata.title
    }

    public static func description(for note: Note) -> String {
        note.metadata.description
    }

    public static func category(for note: Note) -> String {
        note.metadata.group ?? "uncategorized"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
