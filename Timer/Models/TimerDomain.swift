import Foundation

struct TimerSnapshot: Equatable, Sendable {
    var accumulatedTime: TimeInterval
    var startedAt: Date?
    var hourlyRate: Double

    static let empty = TimerSnapshot(accumulatedTime: 0, startedAt: nil, hourlyRate: 0)

    var isRunning: Bool {
        startedAt != nil
    }

    func elapsed(at date: Date) -> TimeInterval {
        let currentInterval = startedAt.map { max(0, date.timeIntervalSince($0)) } ?? 0
        return max(0, accumulatedTime + currentInterval)
    }

    func earnings(at date: Date, participantCount: Int = 1) -> Decimal {
        MoneyMath.earnings(
            seconds: elapsed(at: date),
            hourlyRate: hourlyRate,
            participantCount: participantCount
        )
    }

    mutating func start(hourlyRate: Double, at date: Date) {
        guard !isRunning else {
            return
        }
        if accumulatedTime == 0 {
            self.hourlyRate = MoneyMath.validatedRate(hourlyRate)
        }
        startedAt = date
    }

    mutating func pause(at date: Date) {
        guard let startedAt else {
            return
        }
        accumulatedTime += max(0, date.timeIntervalSince(startedAt))
        self.startedAt = nil
    }

    mutating func reset() {
        self = .empty
    }
}

enum MoneyMath {
    static let maximumHourlyRate = 1_000_000.0

    static func validatedRate(_ rate: Double) -> Double {
        guard rate.isFinite else {
            return 0
        }
        return min(max(rate, 0), maximumHourlyRate)
    }

    static func earnings(
        seconds: TimeInterval,
        hourlyRate: Double,
        participantCount: Int = 1
    ) -> Decimal {
        let safeSeconds = max(0, seconds)
        let safeRate = validatedRate(hourlyRate)
        let safeParticipants = max(1, participantCount)
        let rawValue = Decimal(safeSeconds) * Decimal(safeRate) * Decimal(safeParticipants) / 3_600
        var value = rawValue
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 2, .plain)
        return rounded
    }
}

extension TimeInterval {
    var formattedStopwatch: String {
        let totalHundredths = max(0, Int((self * 100).rounded(.down)))
        let hundredths = totalHundredths % 100
        let totalSeconds = totalHundredths / 100
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds / 60) % 60
        let hours = totalSeconds / 3_600
        return String(format: "%02d:%02d:%02d.%02d", hours, minutes, seconds, hundredths)
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
