import Foundation

public enum MatchRules {
    public static func similarPhoto(_ distances: [Float]) -> Bool { false }
    public static func similarVideo(_ a: MediaItem, _ b: MediaItem, distances: [Float]) -> Bool { false }
    public static func hamming(_ a: UInt64, _ b: UInt64) -> Int { 0 }
    public static func monthKey(_ date: Date, calendar: Calendar = .current) -> String { "" }
}
