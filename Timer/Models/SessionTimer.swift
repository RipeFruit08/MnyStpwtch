import Foundation
import Observation

@MainActor
@Observable
final class SessionTimer {
    private enum Key {
        static let accumulatedTime = "ActiveSession.accumulatedTime"
        static let startedAt = "ActiveSession.startedAt"
        static let hourlyRate = "ActiveSession.hourlyRate"
    }

    private let defaults: UserDefaults
    private(set) var snapshot: TimerSnapshot

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let accumulatedTime = defaults.double(forKey: Key.accumulatedTime)
        let startedAt = defaults.object(forKey: Key.startedAt) as? Date
        let hourlyRate = defaults.double(forKey: Key.hourlyRate)
        snapshot = TimerSnapshot(
            accumulatedTime: accumulatedTime,
            startedAt: startedAt,
            hourlyRate: hourlyRate
        )
    }

    var isRunning: Bool {
        snapshot.isRunning
    }

    func elapsed(at date: Date) -> TimeInterval {
        snapshot.elapsed(at: date)
    }

    func earnings(at date: Date, participantCount: Int = 1) -> Decimal {
        snapshot.earnings(at: date, participantCount: participantCount)
    }

    func toggle(hourlyRate: Double, at date: Date) {
        if snapshot.isRunning {
            snapshot.pause(at: date)
        } else {
            snapshot.start(hourlyRate: hourlyRate, at: date)
        }
        persist()
    }

    func pause(at date: Date) {
        snapshot.pause(at: date)
        persist()
    }

    func reset() {
        snapshot.reset()
        persist()
    }

    private func persist() {
        defaults.set(snapshot.accumulatedTime, forKey: Key.accumulatedTime)
        defaults.set(snapshot.startedAt, forKey: Key.startedAt)
        defaults.set(snapshot.hourlyRate, forKey: Key.hourlyRate)
    }

}
