import Foundation
import Testing
@testable import KeelCore

@Suite("DirectorySizer")
struct DirectorySizerTests {
    @Test func sumsAFolderTree() throws {
        let sandbox = try Sandbox()
        try sandbox.write("Library/Caches/app/a.bin", bytes: 40_000)
        try sandbox.write("Library/Caches/app/nested/b.bin", bytes: 60_000)
        let size = DirectorySizer.allocatedSize(of: sandbox.home.appendingPathComponent("Library/Caches/app"))
        #expect(size >= 100_000)
        #expect(size < 200_000)
    }

    @Test func sizesASingleFile() throws {
        let sandbox = try Sandbox()
        let file = try sandbox.write("Downloads/movie.mov", bytes: 50_000)
        #expect(DirectorySizer.allocatedSize(of: file) >= 50_000)
    }

    @Test func neverFollowsSymlinks() throws {
        let sandbox = try Sandbox()
        try sandbox.write("big.bin", bytes: 2_000_000, in: sandbox.outside)
        try sandbox.write("Library/Caches/app/small.bin", bytes: 1_000)
        _ = try sandbox.symlink("Library/Caches/app/link", to: sandbox.outside)
        let size = DirectorySizer.allocatedSize(of: sandbox.home.appendingPathComponent("Library/Caches/app"))
        #expect(size < 100_000)
    }

    @Test func missingItemIsZero() throws {
        let sandbox = try Sandbox()
        #expect(DirectorySizer.allocatedSize(of: sandbox.home.appendingPathComponent("nope")) == 0)
    }
}
