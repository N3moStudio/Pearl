import Foundation

public enum MatchRules {
    public static func similarPhoto(_ distances: [Float]) -> Bool {
        !distances.isEmpty && distances.allSatisfy { $0.isFinite && $0 >= 0 && $0 <= 0.24 }
    }
    public static func similarVideo(_ a: MediaItem, _ b: MediaItem, distances: [Float]) -> Bool {
        guard a.isVideo, b.isVideo, a.duration > 0, b.duration > 0,
              abs(a.duration - b.duration) <= min(0.5, min(a.duration, b.duration) * 0.02),
              abs(a.aspect - b.aspect) <= 0.03, distances.count == 5 else { return false }
        return distances.allSatisfy { $0.isFinite && $0 >= 0 && $0 <= 0.18 }
    }
    public static func hamming(_ a: UInt64, _ b: UInt64) -> Int { (a ^ b).nonzeroBitCount }
    public static func monthKey(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }
}
