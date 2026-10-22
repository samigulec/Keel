import Testing
import KeelCore

@Suite("ByteFormat")
struct ByteFormatTests {
    @Test(arguments: [
        (Int64(0), "0 B"),
        (Int64(512), "512 B"),
        (Int64(860_000_000), "860 MB"),
        (Int64(999_600_000), "1 GB"),
        (Int64(2_000_000_000), "2 GB"),
        (Int64(4_200_000_000), "4,2 GB"),
        (Int64(11_100_000_000), "11,1 GB"),
        (Int64(200_000_000_000), "200 GB"),
        (Int64(1_500_000_000_000), "1,5 TB"),
    ])
    func formatsLikeTheDesign(bytes: Int64, expected: String) {
        #expect(ByteFormat.string(bytes) == expected)
    }

    @Test func partsSplitNumberFromUnit() {
        #expect(ByteFormat.parts(4_200_000_000) == ("4,2", "GB"))
        #expect(ByteFormat.parts(0) == ("0", "B"))
    }

    @Test func diskSpaceFractions() {
        let disk = DiskSpace(totalBytes: 512, availableBytes: 200)
        #expect(disk.usedBytes == 312)
        #expect(abs(disk.usedFraction - 0.609375) < 0.0001)
        #expect(DiskSpace(totalBytes: 0, availableBytes: 0).usedFraction == 0)
    }
}
