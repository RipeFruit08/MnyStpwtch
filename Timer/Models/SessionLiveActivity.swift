import Foundation

#if canImport(ActivityKit) && os(iOS) && !targetEnvironment(macCatalyst)
import ActivityKit

struct MoneyStopwatchActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        let accumulatedTime: TimeInterval
        let startedAt: Date?
    }

    let hourlyRate: Double
    let currencyCode: String
}

@MainActor
final class SessionLiveActivityController {
    func synchronize(snapshot: TimerSnapshot, currencyCode: String) {
        let state = MoneyStopwatchActivityAttributes.ContentState(
            accumulatedTime: snapshot.accumulatedTime,
            startedAt: snapshot.startedAt
        )
        let shouldEnd = snapshot.accumulatedTime == 0 && snapshot.startedAt == nil
        let shouldStart = snapshot.isRunning
        let hourlyRate = snapshot.hourlyRate

        Task {
            if shouldEnd {
                await endAll(with: state)
                return
            }

            if let activity = Activity<MoneyStopwatchActivityAttributes>.activities.first {
                await activity.update(ActivityContent(state: state, staleDate: nil))
                return
            }

            guard shouldStart, ActivityAuthorizationInfo().areActivitiesEnabled else {
                return
            }

            let attributes = MoneyStopwatchActivityAttributes(
                hourlyRate: hourlyRate,
                currencyCode: currencyCode
            )
            _ = try? Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        }
    }

    private func endAll(with state: MoneyStopwatchActivityAttributes.ContentState) async {
        let finalContent = ActivityContent(state: state, staleDate: nil)
        for activity in Activity<MoneyStopwatchActivityAttributes>.activities {
            await activity.end(finalContent, dismissalPolicy: .immediate)
        }
    }
}
#else
@MainActor
final class SessionLiveActivityController {
    func synchronize(snapshot: TimerSnapshot, currencyCode: String) {}
}
#endif
