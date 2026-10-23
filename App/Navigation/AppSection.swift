/// Top-level destinations in the sidebar.
enum AppSection: String, CaseIterable, Identifiable {
    case smartScan
    case cleanup
    case performance
    case applications
    case largeFiles
    case assistant

    var id: String { rawValue }

    var title: String {
        switch self {
        case .smartScan: "Akıllı Tarama"
        case .cleanup: "Temizlik"
        case .performance: "Performans"
        case .applications: "Uygulamalar"
        case .largeFiles: "Büyük Dosyalar"
        case .assistant: "Keel AI"
        }
    }

    /// The roadmap phase that ships this section (see docs/PLAN.md).
    var phase: Int {
        switch self {
        case .smartScan, .cleanup, .performance, .applications, .largeFiles, .assistant: 1
        }
    }
}
