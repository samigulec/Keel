import Foundation

/// Fixed-length history buffer helpers for live performance readings.
public enum RollingHistory {
    /// Appends `value` to `history` (oldest first) and trims from the front so
    /// at most `limit` values remain. Returns `[]` when `limit <= 0`.
    public static func appending(_ value: Double, to history: [Double], limit: Int) -> [Double] {
        guard limit > 0 else { return [] }
        return Array((history + [value]).suffix(limit))
    }
}
