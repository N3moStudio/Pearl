import Foundation

public enum SwipeDecision: Sendable, Equatable {
    case keep, remove
    /// Decide only on release. A tiny nudge never commits through velocity alone.
    public static func released(x: Double, y: Double, predictedX: Double, width: Double) -> SwipeDecision? {
        guard abs(x) > abs(y) * 1.25, abs(x) >= 28 else { return nil }
        let threshold = max(80, min(width * 0.28, 140))
        let committed = abs(x) >= threshold || (abs(x) >= 45 && abs(predictedX) >= width * 0.65 && x * predictedX > 0)
        guard committed else { return nil }
        return x < 0 ? .remove : .keep
    }
}
