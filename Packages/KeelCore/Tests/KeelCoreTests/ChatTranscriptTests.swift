import Foundation
import Testing
@testable import KeelCore

@Suite("ChatTranscript")
struct ChatTranscriptTests {
    @Test func middleTruncatesOverlongNewestMessageInsteadOfReturningEmpty() {
        let headTag = "START_CONTEXT "
        let tailTag = " END_QUESTION?"
        let longBody = headTag + String(repeating: "a", count: 8_000) + tailTag
        let messages: [ChatTranscript.Message] = [
            .init(role: .user, text: "older message that must not leak"),
            .init(role: .assistant, text: longBody),
        ]

        let result = ChatTranscript.build(messages, maxCharacters: 200)

        #expect(!result.isEmpty)
        #expect(result.count == 200)
        #expect(result.hasPrefix("Keel AI: \(headTag)"))
        #expect(result.contains("\n…\n"))
        #expect(result.hasSuffix(tailTag))
        #expect(!result.contains("older message"))
    }

    @Test func countsSeparatorsWithinBudget() {
        let messages: [ChatTranscript.Message] = [
            .init(role: .user, text: "first"),      // "User: first" -> 11 chars
            .init(role: .assistant, text: "reply"), // "Keel AI: reply" -> 14 chars
            .init(role: .user, text: "last"),       // "User: last" -> 10 chars
        ]
        // Exact budget for last two lines + "\n\n" = 14 + 2 + 10 = 26.
        // Without counting separators, 25 would incorrectly include both (length 26 > 25).
        let tight = ChatTranscript.build(messages, maxCharacters: 25)
        #expect(tight == "User: last")
        #expect(tight.count <= 25)

        let exact = ChatTranscript.build(messages, maxCharacters: 26)
        #expect(exact == "Keel AI: reply\n\nUser: last")
        #expect(exact.count == 26)
    }

    @Test func skipsNoticesAndSuppressesEmptyWrapper() {
        let onlyNotices: [ChatTranscript.Message] = [
            .init(role: .notice, text: "Temizlik tamamlandı."),
            .init(role: .notice, text: "Durduruldu."),
        ]
        #expect(ChatTranscript.build([]) == "")
        #expect(ChatTranscript.build(onlyNotices) == "")
        #expect(ChatTranscript.wrap("") == nil)
        #expect(ChatTranscript.wrap("   \n\t  ") == nil)
        #expect(ChatTranscript.applying("", to: "Disk dolu mu?") == "Disk dolu mu?")
        #expect(ChatTranscript.applying(nil, to: "Disk dolu mu?") == "Disk dolu mu?")
        #expect(ChatTranscript.applying(" \n ", to: "Disk dolu mu?") == "Disk dolu mu?")
    }

    @Test func handlesZeroNegativeAndTinyBudgetsSafely() {
        let messages: [ChatTranscript.Message] = [
            .init(role: .user, text: String(repeating: "x", count: 100)),
        ]
        for budget in [-5, 0, 1, 5, 9, 10, 13, 14] {
            let result = ChatTranscript.build(messages, maxCharacters: budget)
            if budget <= 0 {
                #expect(result.isEmpty)
            } else {
                #expect(result.count <= budget)
            }
        }
        // Prefix "User: " (6) + "\n…\n" (3) = 9, so budget 10 fits 1 body char.
        let minFit = ChatTranscript.build(messages, maxCharacters: 10)
        #expect(minFit == "User: x\n…\n")
        #expect(minFit.count == 10)

        // Budget 9 cannot fit even 1 body char -> returns empty rather than silent/markerless text.
        #expect(ChatTranscript.build(messages, maxCharacters: 9).isEmpty)
    }

    @Test func preservesUnicodeGraphemeClusters() {
        let cluster = "i\u{0307}" // combining dot above
        let family = "👨‍👩‍👧‍👦"
        let flag = "🇹🇷"
        let text = String(repeating: "\(cluster)\(family)\(flag)", count: 40)
        let messages: [ChatTranscript.Message] = [.init(role: .user, text: text)]

        let result = ChatTranscript.build(messages, maxCharacters: 40)
        #expect(result.count <= 40)
        #expect(result.contains("\n…\n"))
        #expect(result.hasPrefix("User: \(cluster)"))
        #expect(result.hasSuffix(flag))
        // Round-tripping through UTF-8 verifies no broken scalar sequences.
        #expect(String(decoding: Data(result.utf8), as: UTF8.self) == result)
    }

    @Test func wrapsPopulatedTranscriptAndRespectsParametricBudget() {
        let messages: [ChatTranscript.Message] = [
            .init(role: .user, text: String(repeating: "a", count: 2_000)),
            .init(role: .assistant, text: String(repeating: "b", count: 2_000)),
        ]

        let compact = ChatTranscript.build(messages, maxCharacters: 1_500)
        #expect(compact.count == 1_500)
        #expect(compact.contains("\n…\n"))

        let full = ChatTranscript.build(messages, maxCharacters: 6_000)
        #expect(full.contains("User: "))
        #expect(full.contains("Keel AI: "))
        #expect(full.count <= 6_000)

        let prompt = ChatTranscript.applying(compact, to: "Devam et")
        #expect(prompt.hasPrefix("<previous_conversation>\n"))
        #expect(prompt.contains("\n</previous_conversation>\n\nDevam et"))
    }
}
