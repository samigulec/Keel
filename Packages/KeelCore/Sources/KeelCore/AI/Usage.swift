import Foundation

/// What one model response used, for the line under the chat box.
public struct TurnUsage: Equatable, Sendable {
    /// The model that answered, e.g. "claude-opus-5-5".
    public var model: String?
    /// Estimated price of this response in US dollars, if known.
    public var costUSD: Double?
    /// Tokens the conversation occupies after this response.
    public var contextTokens: Int?
    public var contextWindow: Int?

    public init(model: String? = nil, costUSD: Double? = nil, contextTokens: Int? = nil, contextWindow: Int? = nil) {
        self.model = model
        self.costUSD = costUSD
        self.contextTokens = contextTokens
        self.contextWindow = contextWindow
    }
}

/// List prices for estimating what a Claude API response cost. Estimates
/// only: the bill comes from Anthropic.
public enum ModelPricing {
    struct Price {
        /// Dollars per million tokens.
        let input: Double
        let output: Double
        let cacheRead: Double
    }

    static let prices: [String: Price] = [
        "claude-opus-5-5": Price(input: 4, output: 20, cacheRead: 0.20),
        "claude-sonnet-5-5": Price(input: 2, output: 10, cacheRead: 0.20),
        "claude-haiku-5-5": Price(input: 0.10, output: 0.50, cacheRead: 0.01),
        "claude-fable-5-1": Price(input: 10, output: 50, cacheRead: 0.25),
        "claude-opus-5": Price(input: 5, output: 25, cacheRead: 0.50),
        "claude-sonnet-5": Price(input: 2, output: 10, cacheRead: 0.20),
    ]

    public static let contextWindow = 1_000_000

    public static func cost(model: String, input: Int, output: Int, cacheRead: Int, cacheWrite: Int) -> Double? {
        guard let price = prices[model] else { return nil }
        let million = 1_000_000.0
        return Double(input) * price.input / million
            + Double(output) * price.output / million
            + Double(cacheRead) * price.cacheRead / million
            // Five-minute cache writes cost 1.25x the input price.
            + Double(cacheWrite) * price.input * 1.25 / million
    }
}

public enum ModelNames {
    /// "claude-opus-5-5" -> "Opus 5.5", "gpt-6.1-sol" -> "GPT-6.1 Sol".
    public static func display(_ id: String) -> String {
        if id.hasPrefix("gpt-") {
            let parts = id.dropFirst("gpt-".count).split(separator: "-")
            guard let version = parts.first else { return id }
            let names = parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }
            return (["GPT-\(version)"] + names).joined(separator: " ")
        }
        guard id.hasPrefix("claude-") else { return id }
        var parts = id.dropFirst("claude-".count).split(separator: "-").map(String.init)
        // Dated snapshots end in an eight-digit date; leave it out.
        if let last = parts.last, last.count == 8, Int(last) != nil { parts.removeLast() }
        guard let family = parts.first else { return id }
        let version = parts.dropFirst().joined(separator: ".")
        return family.prefix(1).uppercased() + family.dropFirst() + (version.isEmpty ? "" : " \(version)")
    }
}
