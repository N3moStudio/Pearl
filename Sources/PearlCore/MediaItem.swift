import Foundation

public struct MediaItem: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var date: Date
    public var modified: Date
    public var isVideo: Bool
    public var isScreenshot: Bool
    public var isLive: Bool
    public var favorite: Bool
    public var width: Int
    public var height: Int
    public var duration: Double

    public init(id: String, date: Date = .distantPast, modified: Date = .distantPast,
                isVideo: Bool = false, isScreenshot: Bool = false, isLive: Bool = false,
                favorite: Bool = false, width: Int = 100, height: Int = 100, duration: Double = 0) {
        self.id = id; self.date = date; self.modified = modified; self.isVideo = isVideo
        self.isScreenshot = isScreenshot; self.isLive = isLive; self.favorite = favorite
        self.width = width; self.height = height; self.duration = duration
    }
    public var aspect: Double { Double(width) / Double(max(height, 1)) }
}

public struct MatchGroup: Identifiable, Codable, Sendable {
    public enum Kind: String, Codable, Sendable { case exact, photo, video }
    public var id: String
    public var kind: Kind
    public var members: [String]
    public init(kind: Kind, members: [String]) {
        self.kind = kind; self.members = members; self.id = kind.rawValue + ":" + (members.first ?? "")
    }
}
