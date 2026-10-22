import Foundation
import Observation

/// Sign-in state of the account providers, shared by the side panel and the
/// model picker. Signing in and out runs the provider's own tool.
@MainActor
@Observable
final class Accounts {
    enum Phase: Equatable {
        case checking
        case notInstalled
        case signedOut
        case signingIn(link: URL?)
        case signedIn(detail: String?)
    }

    private(set) var phases: [AIConnection.Kind: Phase] = [.chatGPT: .checking, .claudeCode: .checking]
    @ObservationIgnored private var loginTasks: [AIConnection.Kind: Task<Void, Never>] = [:]

    func phase(_ kind: AIConnection.Kind) -> Phase {
        if kind == .apple {
            return AppleIntelligence.isAvailable ? .signedIn(detail: nil) : .notInstalled
        }
        return phases[kind] ?? .checking
    }

    func isReady(_ kind: AIConnection.Kind) -> Bool {
        if case .signedIn = phase(kind) { true } else { false }
    }

    static func tool(for kind: AIConnection.Kind) -> CLITool? {
        switch kind {
        case .claudeCode: .claude
        case .chatGPT: .codex
        case .apple: nil
        }
    }

    func refreshAll() async {
        await refresh(.chatGPT)
        await refresh(.claudeCode)
    }

    func refresh(_ kind: AIConnection.Kind) async {
        guard let tool = Self.tool(for: kind) else { return }
        if case .signingIn = phase(kind) { return }
        let account = await tool.account()
        phases[kind] = Self.phase(for: account)
    }

    private static func phase(for account: CLITool.Account) -> Phase {
        if !account.isInstalled { return .notInstalled }
        return account.isLoggedIn ? .signedIn(detail: account.detail) : .signedOut
    }

    /// Opens the provider's own sign-in in the browser and waits for it.
    func signIn(_ kind: AIConnection.Kind) {
        guard let tool = Self.tool(for: kind) else { return }
        loginTasks[kind]?.cancel()
        phases[kind] = .signingIn(link: nil)
        loginTasks[kind] = Task {
            let output = try? await tool.startLogin { link in
                self.phases[kind] = .signingIn(link: link)
            }
            // Poll until the tool reports the account, for up to five minutes.
            for _ in 0..<150 where !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                let account = await tool.account()
                if account.isLoggedIn {
                    phases[kind] = Self.phase(for: account)
                    break
                }
            }
            output?.cancel()
            if case .signingIn = phases[kind] {
                let account = await tool.account()
                phases[kind] = Self.phase(for: account)
            }
        }
    }

    func cancelSignIn(_ kind: AIConnection.Kind) {
        loginTasks[kind]?.cancel()
        loginTasks[kind] = nil
        phases[kind] = .checking
        Task { await refresh(kind) }
    }

    func signOut(_ kind: AIConnection.Kind) async {
        guard let tool = Self.tool(for: kind) else { return }
        phases[kind] = .checking
        await tool.logout()
        await refresh(kind)
    }

    /// Signs out, then straight into the provider's sign-in for another account.
    func switchAccount(_ kind: AIConnection.Kind) async {
        await signOut(kind)
        signIn(kind)
    }

    func signInInTerminal(_ kind: AIConnection.Kind) {
        guard let tool = Self.tool(for: kind) else { return }
        Task { await tool.loginInTerminal() }
    }
}
