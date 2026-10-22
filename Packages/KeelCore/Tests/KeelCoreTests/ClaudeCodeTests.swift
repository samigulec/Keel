import Foundation
import Testing
@testable import KeelCore

@Suite("Claude Code integration")
struct ClaudeCodeTests {
    @Test func parsesStreamedTextAndResult() {
        var parser = ClaudeCodeStreamParser()
        let lines = [
            #"{"type":"system","subtype":"init","session_id":"s-1","model":"claude-opus-5-5"}"#,
            #"{"type":"stream_event","event":{"type":"message_start","message":{}}}"#,
            #"{"type":"stream_event","event":{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Mer"}}}"#,
            #"{"type":"stream_event","event":{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"haba"}}}"#,
            #"{"type":"assistant","message":{"content":[{"type":"text","text":"Merhaba"}]}}"#,
            #"{"type":"result","subtype":"success","is_error":false,"result":"Merhaba","session_id":"s-1"}"#,
        ]
        let events = lines.flatMap { parser.consume($0) }
        #expect(events == [.started(model: "claude-opus-5-5"), .text("Mer"), .text("haba"), .result(sessionID: "s-1", isError: false, message: "Merhaba")])
    }

    @Test func showsFinalTextWhenNothingStreamed() {
        var parser = ClaudeCodeStreamParser()
        let events = parser.consume(#"{"type":"result","subtype":"success","is_error":false,"result":"Tamam","session_id":"s"}"#)
        #expect(events == [.text("Tamam"), .result(sessionID: "s", isError: false, message: "Tamam")])
    }

    @Test func reportsRetriesAndErrors() {
        var parser = ClaudeCodeStreamParser()
        #expect(parser.consume(#"{"type":"system","subtype":"api_retry","attempt":2,"error":"overloaded"}"#) == [.retry(attempt: 2, error: "overloaded")])
        #expect(parser.consume(#"{"type":"result","subtype":"error_during_execution","is_error":true,"session_id":"s"}"#)
            == [.result(sessionID: "s", isError: true, message: "error_during_execution")])
        #expect(parser.consume("not json").isEmpty)
    }

    @Test func readsCostAndContextFromResult() {
        var parser = ClaudeCodeStreamParser()
        let line = #"{"type":"result","subtype":"success","is_error":false,"result":"ok","session_id":"s","total_cost_usd":0.42,"usage":{"input_tokens":2000,"cache_read_input_tokens":40000,"cache_creation_input_tokens":3000,"output_tokens":500},"modelUsage":{"claude-haiku-5-5":{"inputTokens":10,"contextWindow":1000000},"claude-opus-5-5":{"inputTokens":45000,"contextWindow":1000000}}}"#
        let events = parser.consume(line)
        #expect(events.last == .usage(TurnUsage(model: "claude-opus-5-5", costUSD: 0.42, contextTokens: 45_500, contextWindow: 1_000_000)))
    }

    @Test func modelNamesReadWell() {
        #expect(ModelNames.display("claude-opus-5-5") == "Opus 5.5")
        #expect(ModelNames.display("claude-haiku-4-5-20251001") == "Haiku 4.5")
        #expect(ModelNames.display("claude-fable-5-1") == "Fable 5.1")
        #expect(ModelNames.display("llama3.2") == "llama3.2")
    }

    @Test func hidesProposalBlockSplitAcrossChunks() {
        var filter = ProposalStreamFilter()
        var shown = ""
        for chunk in ["Önbellekleri temizleyebilirsin.\n\n``", "`keel-clean", "up\n{\"categories\":[\"userCaches\"],", "\"reason\":\"4 GB yer açar\"}\n```"] {
            shown += filter.feed(chunk)
        }
        let end = filter.finish()
        shown += end.visible
        #expect(shown == "Önbellekleri temizleyebilirsin.\n\n")
        #expect(end.proposals == [["categories": ["userCaches"], "reason": "4 GB yer açar"]])
    }

    @Test func ordinaryCodeBlocksPassThrough() {
        var filter = ProposalStreamFilter()
        var shown = filter.feed("Komut: ``")
        shown += filter.feed("`sh\nls\n```")
        let end = filter.finish()
        shown += end.visible
        #expect(shown == "Komut: ```sh\nls\n```")
        #expect(end.proposals.isEmpty)
    }

    @Test func runsAProcessLineByLine() async throws {
        var lines: [String] = []
        for try await line in try ProcessLines.stream(URL(fileURLWithPath: "/bin/sh"), arguments: ["-c", "printf 'bir\\niki\\nüç'"]) {
            lines.append(line)
        }
        #expect(lines == ["bir", "iki", "üç"])
    }

    @Test func failingProcessCarriesItsError() async throws {
        let result = try await ProcessLines.run(URL(fileURLWithPath: "/bin/sh"), arguments: ["-c", "echo 'giriş yok' >&2; exit 1"])
        #expect(result.status == 1)
        #expect(result.output.contains("giriş yok"))
    }
}
