import Foundation
import KeelCore

/// Keel's undo for cleanups and uninstalls: moves trashed items back.
enum Undo {
    static func restore(_ items: [TrashedItem]) async -> RestoreReport {
        await Task.detached(priority: .userInitiated) {
            TrashRestorer(log: .standard()).restore(items)
        }.value
    }

    /// "12 öğe geri yüklendi (1,2 GB)" plus anything that could not be.
    static func summary(_ report: RestoreReport) -> String {
        var text = "\(report.restored.count) öğe eski yerine geri yüklendi (\(ByteFormat.string(report.restoredBytes)))."
        if !report.failed.isEmpty {
            let names = report.failed.prefix(3).map { "\($0.item.original.lastPathComponent): \($0.message)" }
            text += " Geri yüklenemeyen \(report.failed.count) öğe: " + names.joined(separator: "; ")
        }
        return text
    }
}
