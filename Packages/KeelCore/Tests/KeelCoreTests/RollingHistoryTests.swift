import Testing
@testable import KeelCore

@Suite("RollingHistory")
struct RollingHistoryTests {
    @Test func appendsToEmptyHistory() {
        #expect(RollingHistory.appending(0.4, to: [], limit: 30) == [0.4])
    }

    @Test func growsBelowLimitAndPreservesOrder() {
        var history: [Double] = []
        for value in [1.0, 2.0, 3.0] {
            history = RollingHistory.appending(value, to: history, limit: 5)
        }
        #expect(history == [1.0, 2.0, 3.0])
    }

    @Test func dropsOldestWhenFull() {
        let full = [1.0, 2.0, 3.0]
        #expect(RollingHistory.appending(4.0, to: full, limit: 3) == [2.0, 3.0, 4.0])
    }

    @Test func trimsOversizedHistoryWhenLimitShrinks() {
        let oversized = [1.0, 2.0, 3.0, 4.0, 5.0]
        #expect(RollingHistory.appending(6.0, to: oversized, limit: 3) == [4.0, 5.0, 6.0])
    }

    @Test func zeroAndNegativeLimitsReturnEmpty() {
        #expect(RollingHistory.appending(1.0, to: [0.5], limit: 0).isEmpty)
        #expect(RollingHistory.appending(1.0, to: [0.5], limit: -4).isEmpty)
    }
}
