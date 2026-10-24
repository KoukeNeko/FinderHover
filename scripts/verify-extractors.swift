import Foundation
@testable import FinderHover

/// Regression checks for metadata extraction, run by verify-extractors.py.
@main struct ExtractorChecks {
    @MainActor static func main() async {
        let work = FileManager.default.temporaryDirectory
            .appendingPathComponent("finderhover-extractor-checks-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: work) }

        // zipinfo prints "1 file," (singular) for a single entry.
        let single = zipinfoTotals("1 file, 2 bytes uncompressed, 2 bytes compressed:  0.0%")
        precondition(single?.fileCount == 1 && single?.uncompressedBytes == 2)
        precondition(zipinfoTotals("35 files, 4900000 bytes uncompressed, 1900000 bytes compressed:  61.2%")?.fileCount == 35)

        // A listing larger than a pipe's 64 KB buffer must not stall until the timeout,
        // and an encrypted archive must be reported as encrypted.
        let files = work.appendingPathComponent("files")
        try! FileManager.default.createDirectory(at: files, withIntermediateDirectories: true)
        for index in 1...600 {
            try! "\(index)".write(to: files.appendingPathComponent("entry-\(index).txt"), atomically: true, encoding: .utf8)
        }
        let plainZip = work.appendingPathComponent("plain.zip")
        let lockedZip = work.appendingPathComponent("locked.zip")
        precondition(runCommand("/usr/bin/zip", ["-q", "-j", plainZip.path, files.path + "/entry-1.txt"]) != nil)
        precondition(runCommand("/bin/sh", ["-c", "cd '\(files.path)' && /usr/bin/zip -q -P secret '\(lockedZip.path)' *.txt"], timeout: 30) != nil)

        let one = ArchiveExtractor.extractArchiveMetadata(from: plainZip)
        precondition(one?.fileCount == 1, "single-file zip: \(String(describing: one?.fileCount))")
        let started = Date()
        let locked = ArchiveExtractor.extractArchiveMetadata(from: lockedZip)
        precondition(Date().timeIntervalSince(started) < 2, "large zip listing stalled")
        precondition(locked?.fileCount == 600 && locked?.isEncrypted == true, "encrypted zip: \(String(describing: locked))")

        // The quarantine timestamp counts seconds since 1970.
        let downloaded = work.appendingPathComponent("downloaded.txt")
        try! "x".write(to: downloaded, atomically: true, encoding: .utf8)
        precondition(setxattr(downloaded.path, "com.apple.quarantine", "0083;69898a88;Safari;", 21, 0, 0) == 0)
        let quarantine = SystemExtractor.extractSystemMetadata(from: downloaded)?.quarantineInfo
        precondition(quarantine?.downloadDate == DateFormatters.formatShortDateTime(Date(timeIntervalSince1970: 0x69898a88)))

        // A hovered repository must not be able to make git run its own programs.
        let repo = work.appendingPathComponent("repo")
        let marker = work.appendingPathComponent("marker")
        let setup = """
        mkdir '\(repo.path)' && cd '\(repo.path)' && git init -q && echo x > f && git add f \
        && git -c user.email=a@b -c user.name=a commit -qm init \
        && echo '* filter=evil' > .gitattributes \
        && git config filter.evil.clean "sh -c 'touch \(marker.path)'; cat" \
        && git config core.fsmonitor "sh -c 'touch \(marker.path)' #" && sleep 1 && touch f
        """
        precondition(runCommand("/bin/sh", ["-c", setup], timeout: 30) != nil)
        let git = DeveloperExtractor.extractGitMetadata(from: repo)
        precondition(!FileManager.default.fileExists(atPath: marker.path), "repository config ran a program")
        precondition(git?.currentBranch != nil && git?.commitCount == 1)

        // Extraction must leave the main thread free while it runs.
        var ticks = 0
        let ticker = Task { @MainActor in
            while !Task.isCancelled {
                ticks += 1
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
        }
        _ = await FileInfo.from(path: lockedZip.path)
        _ = await FileInfo.from(path: repo.path)
        ticker.cancel()
        precondition(ticks > 3, "main thread was blocked during extraction (\(ticks) ticks)")

        print("PASS: zip totals, large and encrypted zips, quarantine date, git config programs, off-main extraction.")
    }
}
