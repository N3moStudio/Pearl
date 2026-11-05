import Foundation

public struct ReviewQueue: Codable, Sendable {
    public private(set) var pending: Set<String> = []
    public private(set) var reviewed: Set<String> = []
    public private(set) var protected: Set<String> = []
    private var history: [Change] = []
    private struct Change: Codable, Sendable { let id: String; let pending: Bool; let reviewed: Bool }
    public init() {}
    public var canUndo: Bool { !history.isEmpty }
    public mutating func decide(_ item: MediaItem, remove: Bool) -> Bool { false }
    public mutating func undo() {}
    public mutating func protect(_ id: String) {}
    public mutating func unstage(_ id: String) {}
    public mutating func reconcile(accessible: Set<String>) {}
    public mutating func completedDeletion(_ ids: Set<String>) {}
}
