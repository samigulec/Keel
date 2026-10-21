/// Formats byte counts the way the Keel design shows them: decimal units like
/// Finder, a comma as decimal separator, e.g. "860 MB", "4,2 GB", "200 GB".
public enum ByteFormat {
    private static let units = ["B", "KB", "MB", "GB", "TB", "PB"]

    public static func string(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 B" }

        var value = Double(bytes)
        var unitIndex = 0
        while value >= 1000, unitIndex < units.count - 1 {
            value /= 1000
            unitIndex += 1
        }

        // One decimal only for GB and above, and only while it adds information.
        let showsDecimal = unitIndex >= 3 && value < 100
        if showsDecimal {
            let tenths = Int((value * 10).rounded())
            if tenths % 10 != 0 {
                return "\(tenths / 10),\(tenths % 10) \(units[unitIndex])"
            }
            return "\(tenths / 10) \(units[unitIndex])"
        }

        let rounded = Int(value.rounded())
        // 999,6 MB rounds to "1000 MB"; show it as the next unit instead.
        if rounded >= 1000, unitIndex < units.count - 1 {
            return "1 \(units[unitIndex + 1])"
        }
        return "\(rounded) \(units[unitIndex])"
    }
}
