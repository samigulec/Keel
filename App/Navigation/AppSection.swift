/// Top-level destinations in the sidebar.
enum AppSection: String, CaseIterable, Identifiable {
    case smartScan
    case cleanup
    case performance
    case applications
    case assistant

    var id: String { rawValue }

    var title: String {
        switch self {
        case .smartScan: "Akıllı Tarama"
        case .cleanup: "Temizlik"
        case .performance: "Performans"
        case .applications: "Uygulamalar"
        case .assistant: "Keel AI"
        }
    }

    var symbol: String {
        switch self {
        case .smartScan: "magnifyingglass"
        case .cleanup: "sparkles"
        case .performance: "gauge.with.dots.needle.50percent"
        case .applications: "square.grid.2x2"
        case .assistant: "bubble.left.and.text.bubble.right"
        }
    }

    /// The roadmap phase that ships this section (see docs/PLAN.md).
    var phase: Int {
        switch self {
        case .smartScan, .cleanup, .performance: 1
        case .applications: 2
        case .assistant: 4
        }
    }
}
