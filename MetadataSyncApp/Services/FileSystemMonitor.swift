import Foundation

class FileSystemMonitor {
    private var stream: FSEventStreamRef?
    private let callback: ([String]) -> Void
    private var lastPaths: Set<String> = []
    private var debounceWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 0.5

    init(callback: @escaping ([String]) -> Void) {
        self.callback = callback
    }

    func startMonitoring(paths: [String]) {
        stopMonitoring()

        guard !paths.isEmpty else { return }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let flags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes |
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagNoDefer
        )

        stream = FSEventStreamCreate(
            nil,
            { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
                guard let clientCallBackInfo = clientCallBackInfo else { return }
                let monitor = Unmanaged<FileSystemMonitor>.fromOpaque(clientCallBackInfo).takeUnretainedValue()

                if let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] {
                    monitor.handleEvents(paths: paths)
                }
            },
            &context,
            paths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            debounceInterval,
            flags
        )

        if let stream = stream {
            FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
            FSEventStreamStart(stream)
        }
    }

    private func handleEvents(paths: [String]) {
        lastPaths.formUnion(paths)

        debounceWorkItem?.cancel()
        debounceWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let paths = Array(self.lastPaths)
            self.lastPaths.removeAll()
            self.callback(paths)
        }

        if let workItem = debounceWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
        }
    }

    func stopMonitoring() {
        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        stream = nil
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        lastPaths.removeAll()
    }

    deinit {
        stopMonitoring()
    }
}
