import KeelCore
import SwiftUI

/// One button that checks everything: space, apps, large files and the
/// system's health, then lists what is worth doing.
struct SmartScanView: View {
    var navigate: (AppSection) -> Void
    @Environment(SmartCareModel.self) private var care
    @Environment(ApplicationsModel.self) private var applications
    @Environment(LargeFilesModel.self) private var largeFiles
    @Environment(SystemStatus.self) private var status
    @Environment(\.compactLayout) private var compact
    @State private var confirmingClean = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageHeader(
                title: "Akıllı Tarama",
                subtitle: "Tek tıkla alan, uygulamalar, büyük dosyalar ve sistem sağlığı kontrolü."
            )

            hero

            if care.isRunning {
                steps
            } else if !care.findings.isEmpty {
                findings
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16, alignment: .top), count: compact ? 2 : 3), spacing: 16) {
                storageCard
                memoryCard
                temperatureCard
            }
        }
        .onAppear { if !care.isRunning, care.lastRun != nil { care.evaluate() } }
        .confirmationDialog(
            "\(ByteFormat.string(care.recommendedBytes)) temizlensin mi?",
            isPresented: $confirmingClean,
            titleVisibility: .visible
        ) {
            Button("Temizle") { Task { await care.cleanRecommended() } }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Önerilen kategoriler (önbellekler, günlükler, tarayıcı önbellekleri) Çöp Kutusu'na taşınır; Temizlik ekranından geri alabilirsin.")
        }
    }

    // MARK: Hero

    private var hero: some View {
        HStack(alignment: .center, spacing: 36) {
            ScoreRing(score: care.score, isRunning: care.isRunning, progress: Double(care.finished.count) / Double(SmartCareModel.Step.allCases.count))
                .frame(width: 168, height: 168)

            VStack(alignment: .leading, spacing: 14) {
                if let lastRun = care.lastRun, !care.isRunning {
                    Pill(text: "Son tarama: \(lastRun.formatted(date: .omitted, time: .shortened))")
                } else if care.isRunning {
                    Pill(text: "Taranıyor…", background: Palette.track, foreground: Palette.slate)
                }
                Text(headline)
                    .font(.keel(26, .extraBold))
                    .tracking(-0.4)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Tarama yalnızca okur. Hiçbir şey sen onaylamadan silinmez; silinenler Çöp Kutusu'na gider ve geri alınabilir.")
                    .font(.keel(15, .medium))
                    .foregroundStyle(Palette.slate)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    if care.lastRun != nil, !care.isRunning, care.recommendedBytes >= 100_000_000 {
                        Button("Önerilenleri temizle (\(ByteFormat.string(care.recommendedBytes)))") { confirmingClean = true }
                            .buttonStyle(.keelPrimary)
                        Button("Yeniden tara", action: care.run)
                            .buttonStyle(.keelSecondary)
                    } else {
                        Button(action: care.run) {
                            Label(care.isRunning ? "Taranıyor…" : (care.lastRun == nil ? "Taramayı başlat" : "Yeniden tara"), systemImage: "sparkle.magnifyingglass")
                        }
                        .buttonStyle(.keelPrimary)
                        .disabled(care.isRunning)
                    }
                }
                .padding(.top, 4)
            }
        }
        .keelCard(padding: 32, radius: 24)
    }

    private var headline: String {
        if care.isRunning { return "Mac'in kontrol ediliyor…" }
        guard let score = care.score else {
            return "Tek taramayla neyin yer kapladığını, neyin yavaşlattığını ve neyin güvenle temizlenebileceğini göster."
        }
        let actionable = care.findings.filter { $0.severity >= .attention }.count
        switch score {
        case 90...: return actionable == 0 ? "Mac'in çok iyi durumda." : "Mac'in iyi durumda; \(actionable) şeye bakmak iyi olur."
        case 70..<90: return "Mac'in fena değil; \(max(actionable, 1)) konu ilgilenmeni bekliyor."
        default: return "Mac'in bakım istiyor; \(max(actionable, 1)) önemli konu var."
        }
    }

    // MARK: Progress and findings

    private var steps: some View {
        HStack(spacing: 10) {
            ForEach(SmartCareModel.Step.allCases, id: \.self) { step in
                HStack(spacing: 8) {
                    if care.finished.contains(step) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.keelGreen)
                    } else {
                        ProgressView().controlSize(.small)
                    }
                    Text(step.title)
                        .font(.keel(13, .semibold))
                        .foregroundStyle(care.finished.contains(step) ? Palette.text : Palette.slate)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(Palette.mist, in: Capsule())
            }
        }
    }

    private var findings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bulgular").eyebrowStyle()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14, alignment: .top), count: compact ? 1 : 2), spacing: 14) {
                ForEach(care.findings) { finding in
                    FindingCard(finding: finding) { perform(finding.action) }
                }
            }
        }
    }

    private func perform(_ action: CareFinding.Action?) {
        switch action {
        case .cleanRecommended: confirmingClean = true
        case .open(let section): navigate(section)
        case .unusedApps:
            applications.filter = .unused
            navigate(.applications)
        case .oldFiles:
            largeFiles.age = .oneYear
            navigate(.largeFiles)
        case nil: break
        }
    }

    // MARK: Live cards

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Depolama").eyebrowStyle()
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                ByteAmount(bytes: status.disk?.availableBytes, size: 26)
                Text("boş")
                    .font(.keel(15, .semibold))
                    .foregroundStyle(Palette.slate)
            }
            ProgressBar(fraction: status.disk?.usedFraction ?? 0, tint: (status.disk?.usedFraction ?? 0) > 0.9 ? Palette.warning : nil)
        }
        .keelCard(padding: 22)
    }

    private var memoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bellek (RAM)").eyebrowStyle()
            ByteAmount(bytes: status.memory.map { Int64($0.usedBytes) }, size: 26, base: .binary)
            Text(status.memory.map(memoryDetail) ?? "Ölçülüyor…")
                .font(.keel(13, .medium))
                .foregroundStyle(Palette.slate)
        }
        .keelCard(padding: 22)
    }

    private var temperatureCard: some View {
        let cpu = status.thermals?.summary(.cpu)?.hottest ?? status.thermals?.summaries.map(\.hottest).max()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Sıcaklık").eyebrowStyle(color: Palette.Sidebar.eyebrow)
            Text(cpu.map(Thermal.degrees) ?? "—")
                .font(.keelMono(26, .semibold))
                .tracking(-1.5)
                .foregroundStyle(Palette.text)
            Text(cpu.map { "İşlemci · \(Thermal.state($0).lowercased())" } ?? "Sensörler okunuyor…")
                .font(.keel(13, .medium))
                .foregroundStyle(Palette.Sidebar.text)
        }
        .keelSummaryCard(padding: 22)
    }

    private func memoryDetail(_ memory: MemorySnapshot) -> String {
        let total = ByteFormat.string(Int64(memory.totalBytes), base: .binary)
        let pressure = switch memory.pressure {
        case .normal: "normal"
        case .warning: "yüksek"
        case .critical: "kritik"
        }
        return "\(total) içinden · baskı \(pressure)"
    }
}

/// The health score, or the scan's progress while it runs.
private struct ScoreRing: View {
    let score: Int?
    let isRunning: Bool
    let progress: Double

    var body: some View {
        ZStack {
            Circle().stroke(Palette.track, lineWidth: 14)
            Circle()
                .trim(from: 0, to: isRunning ? max(progress, 0.04) : Double(score ?? 0) / 100)
                .stroke(isRunning ? AnyShapeStyle(Palette.accentBar) : AnyShapeStyle(color), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: progress)
                .animation(.easeOut(duration: 0.8), value: score)
            if isRunning {
                ProgressView().controlSize(.large)
            } else if let score {
                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(.keelMono(46, .semibold))
                        .tracking(-2)
                        .foregroundStyle(Palette.text)
                    Text("sağlık")
                        .font(.keel(13, .bold))
                        .foregroundStyle(Palette.slate)
                }
            } else {
                Mascot(character: .kee, size: 84)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(score.map { "Sağlık puanı \($0)" } ?? "Henüz taranmadı")
    }

    private var color: Color {
        switch score ?? 0 {
        case 85...: Palette.keelGreen
        case 65..<85: Palette.warningText
        default: Palette.danger
        }
    }
}

private struct FindingCard: View {
    let finding: CareFinding
    let act: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Mascot(character: finding.mascot, size: 40)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(finding.title)
                        .font(.keel(15, .bold))
                        .foregroundStyle(Palette.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(finding.detail)
                    .font(.keel(13, .medium))
                    .foregroundStyle(Palette.slate)
                    .fixedSize(horizontal: false, vertical: true)
                if let title = finding.actionTitle, finding.action != nil {
                    Button(title, action: act)
                        .buttonStyle(TileButtonStyle(prominent: finding.severity >= .attention))
                        .padding(.top, 4)
                }
            }
            Spacer(minLength: 0)
        }
        .keelCard(padding: 18, radius: 20)
    }

    private var color: Color {
        switch finding.severity {
        case .good: Palette.keelGreen
        case .info: Palette.info
        case .attention: Palette.warningText
        case .warning: Palette.danger
        }
    }
}
