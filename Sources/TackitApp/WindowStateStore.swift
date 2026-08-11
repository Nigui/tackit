import AppKit

final class WindowStateStore {
    private let defaults = UserDefaults.standard
    private let key = "TackitWindowFrames"

    func frame(for id: UUID) -> NSRect? {
        guard let dict = defaults.dictionary(forKey: key) as? [String: String],
              let value = dict[id.uuidString] else { return nil }
        let rect = NSRectFromString(value)
        return rect.width > 0 && rect.height > 0 ? rect : nil
    }

    func save(_ frame: NSRect, for id: UUID) {
        var dict = (defaults.dictionary(forKey: key) as? [String: String]) ?? [:]
        dict[id.uuidString] = NSStringFromRect(frame)
        defaults.set(dict, forKey: key)
    }

    func remove(id: UUID) {
        var dict = (defaults.dictionary(forKey: key) as? [String: String]) ?? [:]
        dict[id.uuidString] = nil
        defaults.set(dict, forKey: key)
    }
}
