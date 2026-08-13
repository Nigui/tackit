import Foundation

public struct SearchResult: Equatable, Sendable {
    public let noteId: UUID
    public let title: String
    public let snippet: String
    public let score: Double

    public init(noteId: UUID, title: String, snippet: String, score: Double) {
        self.noteId = noteId
        self.title = title
        self.snippet = snippet
        self.score = score
    }
}

public protocol SearchIndex {
    func rebuild(from notes: [Note])
    func upsert(_ note: Note)
    func remove(id: UUID)
    func search(_ query: String, limit: Int) -> [SearchResult]
}

public final class InMemorySearchIndex: SearchIndex {
    private var notes: [UUID: Note] = [:]

    public init() {}

    public func rebuild(from notes: [Note]) {
        self.notes = Dictionary(notes.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
    }

    public func upsert(_ note: Note) {
        notes[note.id] = note
    }

    public func remove(id: UUID) {
        notes[id] = nil
    }

    public func search(_ query: String, limit: Int) -> [SearchResult] {
        let terms = fold(query).split { $0.isWhitespace }.map(String.init).filter { !$0.isEmpty }

        if terms.isEmpty {
            let recent = notes.values.sorted { $0.metadata.updatedAt > $1.metadata.updatedAt }
            return Array(recent.prefix(limit)).map {
                SearchResult(noteId: $0.id, title: displayTitle($0), snippet: snippet($0), score: 0)
            }
        }

        var results: [SearchResult] = []
        for note in notes.values {
            let title = displayTitle(note)
            let titleLower = fold(title)
            let bodyLower = fold(note.body)
            let tagsLower = note.metadata.tags.map { fold($0) }

            var score = 0.0
            for term in terms {
                if titleLower.contains(term) { score += 3 }
                if tagsLower.contains(where: { $0.contains(term) }) { score += 2 }
                if bodyLower.contains(term) { score += 1 }
            }
            if score > 0 {
                results.append(SearchResult(noteId: note.id, title: title, snippet: snippet(note), score: score))
            }
        }

        let ranked = results.sorted { $0.score != $1.score ? $0.score > $1.score : $0.title < $1.title }
        return Array(ranked.prefix(limit))
    }

    private func displayTitle(_ note: Note) -> String {
        NoteDisplay.title(for: note)
    }

    private func snippet(_ note: Note) -> String {
        let flattened = note.body.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
        return String(flattened.prefix(100))
    }

    private func fold(_ string: String) -> String {
        string.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
