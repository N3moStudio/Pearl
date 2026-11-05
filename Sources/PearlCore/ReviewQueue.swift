import Foundation

public struct ReviewQueue: Codable, Sendable {
    public private(set) var pending: Set<String> = []
    public private(set) var reviewed: Set<String> = []
    public private(set) var protected: Set<String> = []
    private var history: [Change] = []
    private struct Change: Codable, Sendable { let id: String; let pending: Bool; let reviewed: Bool }
    public init() {}
    public var canUndo: Bool { !history.isEmpty }
    public var lastUndoID: String? { history.last?.id }
    public mutating func decide(_ item: MediaItem, remove: Bool) -> Bool {
        guard !remove || (!item.favorite && !protected.contains(item.id)) else { return false }
        history.append(Change(id: item.id, pending: pending.contains(item.id), reviewed: reviewed.contains(item.id)))
        if history.count > 100 { history.removeFirst() }
        reviewed.insert(item.id)
        if remove { pending.insert(item.id) } else { pending.remove(item.id) }
        return true
    }
    public mutating func undo() {
        guard let change = history.popLast() else { return }
        if change.pending && !protected.contains(change.id) { pending.insert(change.id) } else { pending.remove(change.id) }
        if change.reviewed { reviewed.insert(change.id) } else { reviewed.remove(change.id) }
    }
    public mutating func protect(_ id: String) {
        protected.insert(id); pending.remove(id); history.removeAll { $0.id == id }
    }
    public mutating func unprotect(_ id: String) { protected.remove(id) }
    public mutating func unstage(_ id: String) {
        pending.remove(id); reviewed.remove(id); history.removeAll { $0.id == id }
    }
    public mutating func reconcile(accessible: Set<String>) {
        pending.formIntersection(accessible); reviewed.formIntersection(accessible)
        protected.formIntersection(accessible); history.removeAll { !accessible.contains($0.id) }
    }
    public mutating func completedDeletion(_ ids: Set<String>) {
        pending.subtract(ids); reviewed.subtract(ids); protected.subtract(ids)
        history.removeAll { ids.contains($0.id) }
    }
}
