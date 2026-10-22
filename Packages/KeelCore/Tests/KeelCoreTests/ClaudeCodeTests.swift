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
        #expect(ModelNames.display("gpt-6.1-sol") == "GPT-6.1 Sol")
        #expect(ModelNames.display("gpt-5.5") == "GPT-5.5")
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

    @Test func mergedErrorOutputArrivesAsLines() async throws {
        let result = try await ProcessLines.run(
            URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "echo 'Logged in using ChatGPT' >&2"],
            mergingStandardError: true
        )
        #expect(result.status == 0)
        #expect(result.output == "Logged in using ChatGPT")
    }
}

@Suite("Codex integration")
struct CodexTests {
    @Test func readsThreadAnswerAndUsage() {
        var parser = CodexStreamParser()
        let lines = [
            #"{"type":"thread.started","thread_id":"0199a213-81c0-7800-8aa1-bbab2a035a53"}"#,
            #"{"type":"turn.started"}"#,
            #"{"type":"item.completed","item":{"id":"item_0","type":"reasoning","text":"Pil verisine bakıyorum"}}"#,
            #"{"type":"item.completed","item":{"id":"item_1","type":"agent_message","text":"Pilin **%87** sağlıkta."}}"#,
            #"{"type":"turn.completed","usage":{"input_tokens":2400,"cached_input_tokens":0,"output_tokens":120,"reasoning_output_tokens":40}}"#,
        ]
        let events = lines.flatMap { parser.consume($0) }
        #expect(events == [
            .started(threadID: "0199a213-81c0-7800-8aa1-bbab2a035a53"),
            .text("Pilin **%87** sağlıkta."),
            .usage(TurnUsage(contextTokens: 2520)),
        ])
    }

    @Test func reportsFailuresWithCodexMessage() {
        var parser = CodexStreamParser()
        _ = parser.consume(#"{"type":"error","message":"Reconnecting... 1/5"}"#)
        #expect(parser.lastError == "Reconnecting... 1/5")
        let events = parser.consume(#"{"type":"turn.failed","error":{"message":"The 'gpt-6.1-sol' model is not supported when using Codex with a ChatGPT account."}}"#)
        #expect(events == [.failed("The 'gpt-6.1-sol' model is not supported when using Codex with a ChatGPT account.")])
        #expect(parser.consume("not json").isEmpty)
    }

    @Test func recognisesErrorsKeelCanActOn() {
        #expect(CLIErrorText.isModelUnavailable("The 'gpt-6.1-sol' model is not supported when using Codex with a ChatGPT account."))
        #expect(CLIErrorText.isModelUnavailable("There's an issue with the selected model (claude-opus-5-5). It may not exist or you may not have access to it."))
        #expect(CLIErrorText.isModelUnavailable(#"API Error: 404 {"type":"error","error":{"type":"not_found_error","message":"model: claude-x"}}"#))
        #expect(!CLIErrorText.isModelUnavailable("Overloaded"))
        #expect(CLIErrorText.needsLogin("Not logged in · Please run /login"))
        #expect(CLIErrorText.isUsageLimit("You've hit your usage limit."))
    }
}
