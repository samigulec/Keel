import Foundation
import Testing
@testable import KeelCore

@Suite("Hardware readers")
struct HardwareReadersTests {
    // MARK: GPU

    @Test func appleSiliconGPU() throws {
        let properties: [String: Any] = [
            "model": "Apple M2 Pro",
            "gpu-core-count": NSNumber(value: 19),
            "PerformanceStatistics": [
                "Device Utilization %": NSNumber(value: 37),
                "Renderer Utilization %": NSNumber(value: 35),
                "In use system memory": NSNumber(value: 1_610_612_736),
            ] as [String: Any],
        ]
        let gpu = try #require(GPUReader.snapshot(from: properties))
        #expect(gpu.name == "Apple M2 Pro")
        #expect(gpu.coreCount == 19)
        #expect(abs(gpu.utilization - 0.37) < 0.0001)
        #expect(gpu.memoryInUseBytes == 1_610_612_736)
    }

    @Test func discreteGPUReportsVRAM() throws {
        let properties: [String: Any] = [
            "PerformanceStatistics": ["Device Utilization %": 5, "vramUsedBytes": 268_435_456] as [String: Any],
        ]
        let gpu = try #require(GPUReader.snapshot(from: properties))
        #expect(gpu.name == nil)
        #expect(gpu.memoryInUseBytes == 268_435_456)
    }

    @Test func acceleratorWithoutStatisticsIsIgnored() {
        #expect(GPUReader.snapshot(from: ["model": "Display"]) == nil)
    }

    // MARK: Storage

    @Test func diskTotalsSumAllDrivers() throws {
        let drivers: [[String: Any]] = [
            ["Statistics": ["Bytes (Read)": NSNumber(value: 1_000), "Bytes (Write)": NSNumber(value: 400)] as [String: Any]],
            ["Statistics": ["Bytes (Read)": 500, "Bytes (Write)": 100] as [String: Any]],
            ["Other": 1],
        ]
        #expect(StorageReader.totals(fromDrivers: drivers) == DiskIOTotals(readBytes: 1_500, writtenBytes: 500))
        #expect(StorageReader.totals(fromDrivers: []) == nil)
    }

    @Test func diskRatesNeverGoNegative() {
        let earlier = DiskIOTotals(readBytes: 1_000, writtenBytes: 5_000)
        let later = DiskIOTotals(readBytes: 5_000, writtenBytes: 1_000)
        let rate = StorageReader.rate(from: earlier, to: later, seconds: 2)
        #expect(rate == DiskIORate(readPerSecond: 2_000, writePerSecond: 0))
        #expect(StorageReader.rate(from: earlier, to: later, seconds: 0) == DiskIORate(readPerSecond: 0, writePerSecond: 0))
    }

    @Test func internalSSDDevice() throws {
        let properties: [String: Any] = [
            "Device Characteristics": ["Product Name": "APPLE SSD AP0512Z ", "Medium Type": "Solid State"],
            "Protocol Characteristics": ["Physical Interconnect": "Apple Fabric", "Physical Interconnect Location": "Internal"],
        ]
        let device = try #require(StorageReader.device(from: properties))
        #expect(device == StorageDevice(model: "APPLE SSD AP0512Z", isSolidState: true, interconnect: "Apple Fabric", isInternal: true))
    }

    // MARK: Battery

    @Test func appleSiliconBattery() throws {
        let properties: [String: Any] = [
            "CurrentCapacity": 82, "MaxCapacity": 100,
            "AppleRawMaxCapacity": 5_103, "DesignCapacity": 6_075,
            "CycleCount": 213, "Temperature": 3_050,
            "IsCharging": true, "ExternalConnected": true,
        ]
        let battery = try #require(BatteryReader.snapshot(from: properties))
        #expect(abs(battery.charge - 0.82) < 0.0001)
        #expect(abs((battery.health ?? 0) - 0.84) < 0.001)
        #expect(battery.cycleCount == 213)
        #expect(battery.temperatureCelsius == 30.5)
        #expect(battery.isCharging && battery.isPluggedIn)
    }

    @Test func intelBatteryReportsMilliampHours() throws {
        let properties: [String: Any] = [
            "CurrentCapacity": 2_500, "MaxCapacity": 5_000, "DesignCapacity": 6_000, "CycleCount": 900,
        ]
        let battery = try #require(BatteryReader.snapshot(from: properties))
        #expect(battery.charge == 0.5)
        #expect(abs((battery.health ?? 0) - 5_000.0 / 6_000) < 0.0001)
        #expect(!battery.isCharging)
    }

    @Test func noBatteryData() {
        #expect(BatteryReader.snapshot(from: [:]) == nil)
    }

    // MARK: CPU and memory

    @Test func perCoreTicksFromProcStat() {
        let text = "cpu  10 0 10 80\ncpu0 5 0 5 40\ncpu1 5 0 5 40\nintr 1\n"
        #expect(CPUReader.parsePerCoreProcStat(text) == [
            CPUTicks(user: 5, system: 5, idle: 40, nice: 0),
            CPUTicks(user: 5, system: 5, idle: 40, nice: 0),
        ])
    }

    @Test func userAndSystemSplit() {
        let earlier = CPUTicks(user: 0, system: 0, idle: 0, nice: 0)
        let later = CPUTicks(user: 30, system: 10, idle: 50, nice: 10)
        let split = CPUReader.split(from: earlier, to: later)
        #expect(abs(split.user - 0.4) < 0.0001)
        #expect(abs(split.system - 0.1) < 0.0001)
    }

    @Test func liveReadersDoNotCrash() throws {
        let cores = try #require(CPUReader.perCoreTicks())
        #expect(!cores.isEmpty)
        let info = SystemInfo.current()
        #expect(info.logicalCores > 0)
        #expect(info.physicalMemoryBytes > 0)
        #expect(SystemInfo.loadAverages()?.count == 3)
        // Present or not depending on the machine; must simply not crash.
        _ = GPUReader.current()
        _ = BatteryReader.current()
        _ = StorageReader.ioTotals()
        _ = StorageReader.startupDevice()
    }

    @Test func swapFromMeminfo() throws {
        let snapshot = try #require(MemoryReader.parseMeminfo(
            "MemTotal: 1000 kB\nMemAvailable: 500 kB\nSwapTotal: 300 kB\nSwapFree: 100 kB\n"))
        #expect(snapshot.swapUsedBytes == 200 * 1024)
    }
}

@Suite("Temperature and fan sensors")
struct SensorTests {
    @Test func decodesSMCTypes() {
        // 2,000 RPM as Apple silicon's float, and as Intel's fpe2.
        let float: [UInt8] = [0x00, 0x00, 0xFA, 0x44]
        #expect(SMCValue.decode(type: "flt ", bytes: float) == 2_000)
        #expect(SMCValue.decode(type: "fpe2", bytes: [0x1F, 0x40]) == 2_000)
        #expect(SMCValue.decode(type: "sp78", bytes: [0x2D, 0x80]) == 45.5)
        #expect(SMCValue.decode(type: "sp78", bytes: [0xFF, 0x00]) == -1)
        #expect(SMCValue.decode(type: "ui8 ", bytes: [2]) == 2)
        #expect(SMCValue.decode(type: "ui16", bytes: [0x01, 0x00]) == 256)
        #expect(SMCValue.decode(type: "ch8*", bytes: [1]) == nil)
        #expect(SMCValue.decode(type: "flt ", bytes: [1]) == nil)
    }

    @Test func groupsSensorsByName() {
        #expect(SensorReader.group(for: "PMU tdie3") == .cpu)
        #expect(SensorReader.group(for: "pACC MTR Temp Sensor2") == .cpu)
        #expect(SensorReader.group(for: "GPU MTR Temp Sensor1") == .gpu)
        #expect(SensorReader.group(for: "SOC MTR Temp Sensor0") == .soc)
        #expect(SensorReader.group(for: "PMU tdev1") == .soc)
        #expect(SensorReader.group(for: "NAND CH0 temp") == .ssd)
        #expect(SensorReader.group(for: "gas gauge battery") == .battery)
        #expect(SensorReader.group(for: "Palm rest") == .other)
    }

    @Test func dropsCalibrationDuplicatesAndNonsense() {
        let sensors = SensorReader.sensors(from: [
            ("PMU tdie1", 48.5), ("PMU tdie2", 52.0), ("PMU tdie1", 49.0),
            ("PMU tcal", 51.3), ("GPU MTR Temp Sensor1", -40), ("NAND CH0 temp", 36.0), ("", 30),
        ])
        #expect(sensors.map(\.name) == ["PMU tdie1", "PMU tdie2", "NAND CH0 temp"])

        let snapshot = ThermalSnapshot(sensors: sensors, fans: [], hasFans: false)
        let cpu = snapshot.summary(.cpu)
        #expect(cpu?.hottest == 52.0)
        #expect(cpu?.average == 50.25)
        #expect(cpu?.sensorCount == 2)
        #expect(snapshot.summary(.gpu) == nil)
    }

    @Test func fanFractionBetweenMinimumAndMaximum() {
        #expect(FanReading(index: 0, rpm: 3_500, minimumRPM: 1_000, maximumRPM: 6_000).fraction == 0.5)
        #expect(FanReading(index: 0, rpm: 0, minimumRPM: 1_000, maximumRPM: 6_000).fraction == 0)
        #expect(FanReading(index: 0, rpm: 2_000, minimumRPM: nil, maximumRPM: 6_000).fraction == nil)
    }

    @Test func liveSnapshotDoesNotCrash() {
        _ = SensorReader.snapshot()
    }
}
