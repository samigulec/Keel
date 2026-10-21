import Foundation
import KeelCore
import Observation

/// Live system readings shared by the main window and the menu bar.
@MainActor
@Observable
final class SystemStatus {
    private(set) var disk: DiskSpace?

    private let refreshInterval: Duration = .seconds(30)
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    init() {
        refreshTask = Task { [weak self, refreshInterval] in
            while !Task.isCancelled {
                self?.refresh()
                try? await Task.sleep(for: refreshInterval)
            }
        }
    }

    func refresh() {
        disk = try? DiskSpace.current(for: FileManager.default.homeDirectoryForCurrentUser)
    }
}
