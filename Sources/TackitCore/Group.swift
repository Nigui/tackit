import Foundation

public struct Group: Hashable, Codable, Sendable, Identifiable {
    public var id: String { name }
    public let name: String
    public init(_ name: String) { self.name = name }
}

public struct Tag: Hashable, Codable, Sendable, Identifiable {
    public var id: String { name }
    public let name: String
    public init(_ name: String) { self.name = name }
}
