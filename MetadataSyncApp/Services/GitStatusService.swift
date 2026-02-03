import Foundation

struct GitStatus {
    let isGitRepo: Bool
    let hasUncommittedChanges: Bool
}

class GitStatusService {
    private var cache: [String: (status: GitStatus, timestamp: Date)] = [:]
    private let cacheTTL: TimeInterval = 30
    private let maxConcurrent = 4

    func checkGitStatus(at url: URL) -> GitStatus {
        let path = url.path

        // Check cache
        if let cached = cache[path], Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            return cached.status
        }

        let gitPath = url.appendingPathComponent(".git")
        let isGitRepo = FileManager.default.fileExists(atPath: gitPath.path)

        guard isGitRepo else {
            let status = GitStatus(isGitRepo: false, hasUncommittedChanges: false)
            cache[path] = (status, Date())
            return status
        }

        let hasChanges = checkForUncommittedChanges(at: url)
        let status = GitStatus(isGitRepo: true, hasUncommittedChanges: hasChanges)
        cache[path] = (status, Date())
        return status
    }

    private func checkForUncommittedChanges(at url: URL) -> Bool {
        let process = Process()
        process.currentDirectoryURL = url
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["status", "--porcelain"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            return false
        }
    }

    func checkGitStatusBatch(urls: [URL]) async -> [URL: GitStatus] {
        var results: [URL: GitStatus] = [:]

        await withTaskGroup(of: (URL, GitStatus).self) { group in
            var pendingCount = 0

            for url in urls {
                if pendingCount >= maxConcurrent {
                    if let result = await group.next() {
                        results[result.0] = result.1
                        pendingCount -= 1
                    }
                }

                group.addTask {
                    let status = self.checkGitStatus(at: url)
                    return (url, status)
                }
                pendingCount += 1
            }

            for await result in group {
                results[result.0] = result.1
            }
        }

        return results
    }

    func invalidateCache(for path: String) {
        cache.removeValue(forKey: path)
    }

    func clearCache() {
        cache.removeAll()
    }
}
