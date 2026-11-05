@preconcurrency import BackgroundTasks
import UIKit
import PearlCore

/// Main-queue ownership keeps the legacy BGTask object off actor crossings.
@MainActor final class BackgroundScan {
    private var identifier: String?
    private var task: BGTask?
    private var start: (@MainActor @Sendable () -> Void)?
    private var expiration: (@MainActor @Sendable () -> Void)?
    private var token = UUID()
    private var saving: UIBackgroundTaskIdentifier = .invalid
    var running: Bool { task != nil }

    func request(start: @escaping @MainActor @Sendable () -> Void,
                 expiration: @escaping @MainActor @Sendable () -> Void) -> Bool {
        guard #available(iOS 26.0, *) else { return false }
        self.start = start; self.expiration = expiration; token = UUID()
        let current = token
        let identifier = (Bundle.main.bundleIdentifier ?? "com.n3mostudio.pearl") + ".scan." + current.uuidString
        self.identifier = identifier
        let registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { [weak self] task in
            // Apple's explicitly supplied main dispatch queue guarantees this executor.
            MainActor.assumeIsolated {
                guard let self else { task.setTaskCompleted(success: false); return }
                self.accept(task, token: current)
            }
        }
        guard registered else { return false }
        let request = BGContinuedProcessingTaskRequest(identifier: identifier, title: "Pearl is checking", subtitle: "Preparing your library")
        request.strategy = .fail
        do { try BGTaskScheduler.shared.submit(request); return true }
        catch { self.start = nil; self.expiration = nil; return false }
    }
    private func accept(_ incoming: BGTask, token: UUID) {
        guard self.token == token, let start else { incoming.setTaskCompleted(success: false); return }
        task = incoming
        let current = token
        incoming.expirationHandler = { [weak self] in
            Task { @MainActor in
                guard let self, self.token == current else { return }
                self.expiration?()
            }
        }
        self.start = nil
        start()
    }
    func update(_ state: ScanProgress) {
        if #available(iOS 26.0, *), let continued = task as? BGContinuedProcessingTask {
            continued.progress.totalUnitCount = 10_000
            continued.progress.completedUnitCount = Int64(state.fraction * 10_000)
            continued.updateTitle(state.phase == .verifying ? "Pearl is verifying copies" : "Pearl is checking", subtitle: state.detail)
        }
    }
    func finish(success: Bool) {
        token = UUID()
        task?.setTaskCompleted(success: success); task = nil
        start = nil; expiration = nil
        if let identifier { BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier) }
        identifier = nil
        endSaving()
    }
    /// Older iOS gets only a short lease to cancel and checkpoint, never an unlimited scan.
    func beginSaving() {
        guard saving == .invalid else { return }
        saving = UIApplication.shared.beginBackgroundTask(withName: "Save Pearl scan") { [weak self] in
            Task { @MainActor in self?.endSaving() }
        }
    }
    private func endSaving() {
        if saving != .invalid { UIApplication.shared.endBackgroundTask(saving); saving = .invalid }
    }
}
