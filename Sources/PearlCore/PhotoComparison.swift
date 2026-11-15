import Foundation

public enum PhotoComparisonVerdict: String, Sendable {
    case exact, similar, different, unavailable

    public static func classify(exactConfirmed: Bool, distance: Float?) -> Self {
        if exactConfirmed { return .exact }
        guard let distance, distance.isFinite, distance >= 0 else { return .unavailable }
        return MatchRules.similarPhoto([distance]) ? .similar : .different
    }
}
