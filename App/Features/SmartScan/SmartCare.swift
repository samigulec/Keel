import KeelCore
import Observation
import SwiftUI

/// One thing Smart Scan found, and where to deal with it.
struct CareFinding: Identifiable, Equatable {
    enum Severity: Int, Comparable {
        case good, info, attention, warning
        static func < (a: Severity, b: Severity) -> Bool { a.rawValue < b.rawValue }
    }

    enum Action: Equatable {
        case cleanRecommended
        case open(AppSection)
        case unusedApps
        case oldFiles
    }

    let id: String
    let title: String
    let detail: String
    let severity: Severity
    let mascot: Mascot.Character
    var action: Action?
    var actionTitle: String?
}

/// Everything Smart Scan looks at, read from the other screens' models.
struct CareInputs {
    var recommendedBytes: Int64 = 0
    var optInBytes: Int64 = 0
    var unusedApps: [AppEntry] = []
    var intelApps = 0
    var oldFilesBytes: Int64 = 0
    var oldFilesCount = 0
    var disk: DiskSpace?
    var memory: MemorySnapshot?
    var hottestCPU: Double?
    var battery: BatterySnapshot?
    var startupItems = 0
}

enum CareReport {
    /// A 0...100 score and the findings, most pressing first.
    static func evaluate(_ inputs: CareInputs) -> (score: Int, findings: [CareFinding]) {
        var score = 100
        var findings: [CareFinding] = []

        // Space that can go safely.
        if inputs.recommendedBytes >= 100_000_000 {
            score -= inputs.recommendedBytes >= 5_000_000_000 ? 12 : inputs.recommendedBytes >= 1_000_000_000 ? 7 : 3
            findings.append(CareFinding(
                id: "clean",
                title: "\(ByteFormat.string(inputs.recommendedBytes)) güvenle temizlenebilir",
                detail: "Uygulama önbellekleri, eski günlükler ve tarayıcı önbellekleri. Gerekince yeniden oluşturulurlar.",
                severity: inputs.recommendedBytes >= 1_000_000_000 ? .attention : .info,
                mascot: .puf, action: .cleanRecommended, actionTitle: "Temizle"
            ))
        } else {
            findings.append(CareFinding(id: "clean", title: "Önbellekler temiz", detail: "Temizlenecek kayda değer bir şey yok.", severity: .good, mascot: .puf))
        }

        // Disk space.
        if let disk = inputs.disk {
            let free = ByteFormat.string(disk.availableBytes)
            if disk.usedFraction > 0.9 {
                score -= 20
                findings.append(CareFinding(
                    id: "disk", title: "Disk neredeyse dolu: \(free) boş",
                    detail: "Boş alan %10'un altına düşünce macOS yavaşlar ve güncellemeler kurulamaz.",
                    severity: .warning, mascot: .kutu, action: .oldFiles, actionTitle: "Büyük dosyalara bak"
                ))
            } else if disk.usedFraction > 0.8 {
                score -= 8
                findings.append(CareFinding(
                    id: "disk", title: "Disk dolmaya başladı: \(free) boş",
                    detail: "Büyük ve eski dosyalara göz atmak iyi olur.",
                    severity: .attention, mascot: .kutu, action: .oldFiles, actionTitle: "Büyük dosyalara bak"
                ))
            }
        }

        // Old large files.
        if inputs.oldFilesBytes >= 500_000_000 {
            score -= 4
            findings.append(CareFinding(
                id: "old-files",
                title: "\(inputs.oldFilesCount) büyük dosya 1 yıldır açılmamış",
                detail: "Toplam \(ByteFormat.string(inputs.oldFilesBytes)). Hâlâ gerekli olup olmadıklarına bak.",
                severity: .info, mascot: .kutu, action: .oldFiles, actionTitle: "Gözden geçir"
            ))
        }

        // Apps.
        if !inputs.unusedApps.isEmpty {
            score -= min(inputs.unusedApps.count, 5)
            let names = inputs.unusedApps.prefix(3).map(\.app.name).joined(separator: ", ")
            let size = inputs.unusedApps.reduce(0) { $0 + ($1.sizeBytes ?? 0) }
            findings.append(CareFinding(
                id: "unused-apps",
                title: "\(inputs.unusedApps.count) uygulama 90 günden uzun süredir açılmamış",
                detail: "\(names)\(inputs.unusedApps.count > 3 ? " ve diğerleri" : "")\(size > 0 ? " · \(ByteFormat.string(size))" : "")",
                severity: .info, mascot: .blok, action: .unusedApps, actionTitle: "Gözden geçir"
            ))
        }
        if inputs.intelApps > 0 {
            findings.append(CareFinding(
                id: "intel",
                title: "\(inputs.intelApps) uygulama Intel için yapılmış",
                detail: "Rosetta ile çalışırlar; Apple silicon sürümleri daha hızlı ve az pil tüketir.",
                severity: .info, mascot: .blok, action: .open(.applications), actionTitle: "Uygulamalara git"
            ))
        }

        // Memory.
        if let memory = inputs.memory {
            switch memory.pressure {
            case .critical:
                score -= 20
                findings.append(CareFinding(
                    id: "memory", title: "Bellek baskısı kritik",
                    detail: "Mac belleği diske taşımak zorunda kalıyor; bu her şeyi yavaşlatır. En çok bellek kullananları kapatmayı dene.",
                    severity: .warning, mascot: .zip, action: .open(.performance), actionTitle: "Performansa git"
                ))
            case .warning:
                score -= 8
                findings.append(CareFinding(
                    id: "memory", title: "Bellek baskısı yüksek",
                    detail: "Çok sayıda uygulama ya da sekme açık olabilir.",
                    severity: .attention, mascot: .zip, action: .open(.performance), actionTitle: "Performansa git"
                ))
            case .normal:
                findings.append(CareFinding(
                    id: "memory", title: "Bellek rahat",
                    detail: "Kullanılan belleğin çoğu önbellek; baskı normal, bu sağlıklı bir durum.",
                    severity: .good, mascot: .zip
                ))
            }
        }

        // Heat.
        if let hottest = inputs.hottestCPU, hottest >= 90 {
            score -= 8
            findings.append(CareFinding(
                id: "heat", title: "İşlemci çok sıcak: \(Int(hottest.rounded())) °C",
                detail: "Uzun süre böyle kalırsa Mac kendini yavaşlatır. Ağır çalışan bir süreç olabilir.",
                severity: .attention, mascot: .zip, action: .open(.performance), actionTitle: "Sıcaklıklara bak"
            ))
        }

        // Battery.
        if let battery = inputs.battery, let health = battery.health, health < 0.8 {
            score -= 5
            findings.append(CareFinding(
                id: "battery", title: "Pil sağlığı %\(Int((health * 100).rounded()))",
                detail: "Apple %80'in altında servis öneriyor\(battery.cycleCount.map { "; \($0) şarj döngüsü" } ?? "").",
                severity: .attention, mascot: .zip, action: .open(.performance), actionTitle: "Pile bak"
            ))
        }

        // Startup.
        if inputs.startupItems >= 15 {
            score -= 3
            findings.append(CareFinding(
                id: "startup", title: "\(inputs.startupItems) servis kendiliğinden başlıyor",
                detail: "Çok sayıda arka plan servisi açılışı ve pili etkileyebilir.",
                severity: .info, mascot: .zip, action: .open(.performance), actionTitle: "Servislere bak"
            ))
        }

        findings.sort { $0.severity > $1.severity }
        return (max(min(score, 100), 0), findings)
    }
}

/// Runs every check at once and keeps the latest result.
@MainActor
@Observable
final class SmartCareModel {
    enum Step: String, CaseIterable {
        case cleanup, apps, files, system

        var title: String {
            switch self {
            case .cleanup: "Temizlenebilir alan"
            case .apps: "Uygulamalar"
            case .files: "Büyük dosyalar"
            case .system: "Sistem sağlığı"
            }
        }
    }

    private(set) var isRunning = false
    private(set) var finished: Set<Step> = []
    private(set) var score: Int?
    private(set) var findings: [CareFinding] = []
    private(set) var lastRun: Date?

    private let status: SystemStatus
    private let cleanup: CleanupModel
    private let applications: ApplicationsModel
    private let largeFiles: LargeFilesModel
    private let performance: PerformanceModel

    init(status: SystemStatus, cleanup: CleanupModel, applications: ApplicationsModel, largeFiles: LargeFilesModel, performance: PerformanceModel) {
        self.status = status
        self.cleanup = cleanup
        self.applications = applications
        self.largeFiles = largeFiles
        self.performance = performance
    }

    func run() {
        guard !isRunning else { return }
        isRunning = true
        finished = []
        Task {
            // The checks read different things, so they run side by side.
            async let cleaned: Void = runCleanup()
            async let apps: Void = runApps()
            async let files: Void = runFiles()
            async let system: Void = runSystem()
            _ = await (cleaned, apps, files, system)
            evaluate()
            lastRun = Date()
            isRunning = false
        }
    }

    private func runCleanup() async {
        _ = await cleanup.scanAndWait()
        finished.insert(.cleanup)
    }

    private func runApps() async {
        applications.scan()
        _ = await applications.listWhenReady()
        finished.insert(.apps)
    }

    private func runFiles() async {
        if largeFiles.phase != .ready { _ = await largeFiles.filesWhenReady() }
        finished.insert(.files)
    }

    private func runSystem() async {
        status.refresh()
        await performance.refreshLaunchItems()
        finished.insert(.system)
    }

    /// Re-reads the other screens, e.g. after a cleanup from here.
    func evaluate() {
        var inputs = CareInputs()
        inputs.recommendedBytes = cleanup.recommendedBytes
        inputs.optInBytes = cleanup.optInBytes
        inputs.unusedApps = applications.apps.filter { applications.isUnused($0) && !$0.app.isSystem }
        inputs.intelApps = applications.apps.filter { $0.app.architecture == .intel }.count
        let old = largeFiles.files.filter { largeFiles.isOlder($0, than: .oneYear) }
        inputs.oldFilesBytes = old.reduce(0) { $0 + $1.sizeBytes }
        inputs.oldFilesCount = old.count
        inputs.disk = status.disk
        inputs.memory = status.memory
        inputs.hottestCPU = status.thermals?.summary(.cpu)?.hottest
        inputs.battery = status.battery
        inputs.startupItems = performance.activeLaunchItems.count
        (score, findings) = CareReport.evaluate(inputs)
    }

    /// Cleans the recommended categories, as Temizlik would with its default selection.
    func cleanRecommended() async {
        cleanup.selectRecommended()
        _ = await cleanup.cleanSelectionAndWait()
        evaluate()
    }

    var recommendedBytes: Int64 { cleanup.recommendedBytes }
}
