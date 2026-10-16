import SwiftUI
import WidgetKit

#if !targetEnvironment(macCatalyst)
import ActivityKit

struct MoneyStopwatchActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let accumulatedTime: TimeInterval
        let startedAt: Date?
    }

    let hourlyRate: Double
    let currencyCode: String
}

struct MoneyStopwatchLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MoneyStopwatchActivityAttributes.self) { context in
            SessionActivityLockScreenView(
                accumulatedTime: context.state.accumulatedTime,
                startedAt: context.state.startedAt,
                hourlyRate: context.attributes.hourlyRate,
                currencyCode: context.attributes.currencyCode
            )
            .activityBackgroundTint(.indigo.opacity(0.18))
            .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ActivityMetric(title: "TIME") {
                        LiveElapsedView(
                            accumulatedTime: context.state.accumulatedTime,
                            startedAt: context.state.startedAt
                        )
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ActivityMetric(title: "VALUE", alignment: .trailing) {
                        LiveValueView(
                            accumulatedTime: context.state.accumulatedTime,
                            startedAt: context.state.startedAt,
                            hourlyRate: context.attributes.hourlyRate,
                            currencyCode: context.attributes.currencyCode
                        )
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label(
                            context.state.startedAt == nil ? "Session paused" : "Money Stopwatch",
                            systemImage: context.state.startedAt == nil ? "pause.fill" : "stopwatch.fill"
                        )
                        Spacer()
                        Text(context.attributes.hourlyRate, format: .currency(code: context.attributes.currencyCode))
                        Text("/ hr")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: context.state.startedAt == nil ? "pause.fill" : "stopwatch.fill")
                    .foregroundStyle(.indigo)
            } compactTrailing: {
                LiveValueView(
                    accumulatedTime: context.state.accumulatedTime,
                    startedAt: context.state.startedAt,
                    hourlyRate: context.attributes.hourlyRate,
                    currencyCode: context.attributes.currencyCode,
                    compact: true
                )
            } minimal: {
                Image(systemName: "stopwatch.fill")
                    .foregroundStyle(.indigo)
            }
        }
    }
}

private struct SessionActivityLockScreenView: View {
    let accumulatedTime: TimeInterval
    let startedAt: Date?
    let hourlyRate: Double
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: startedAt == nil ? "pause.circle.fill" : "stopwatch.fill")
                    .foregroundStyle(.indigo)
                Text(startedAt == nil ? "Session Paused" : "Session in Progress")
                    .font(.headline)
                Spacer()
                Text(hourlyRate, format: .currency(code: currencyCode))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("/ hr")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 24) {
                ActivityMetric(title: "ELAPSED") {
                    LiveElapsedView(accumulatedTime: accumulatedTime, startedAt: startedAt)
                }
                ActivityMetric(title: "VALUE", alignment: .trailing) {
                    LiveValueView(
                        accumulatedTime: accumulatedTime,
                        startedAt: startedAt,
                        hourlyRate: hourlyRate,
                        currencyCode: currencyCode
                    )
                }
            }
        }
        .padding()
    }
}

private struct LiveElapsedView: View {
    let accumulatedTime: TimeInterval
    let startedAt: Date?
    var compact = false

    var body: some View {
        Group {
            if let effectiveStartDate {
                Text(
                    .currentDate,
                    format: .stopwatch(
                        startingAt: effectiveStartDate,
                        maxPrecision: .seconds(1)
                    )
                )
            } else {
                Text(.seconds(accumulatedTime), format: .time(pattern: .hourMinuteSecond))
            }
        }
                .font(compact ? .caption2 : .headline)
                .monospacedDigit()
                .lineLimit(1)
    }

    private var effectiveStartDate: Date? {
        startedAt?.addingTimeInterval(-max(0, accumulatedTime))
    }
}

private struct LiveValueView: View {
    let accumulatedTime: TimeInterval
    let startedAt: Date?
    let hourlyRate: Double
    let currencyCode: String
    var compact = false

    var body: some View {
        Text(currentValue, format: .currency(code: currencyCode))
            .font(compact ? .caption2 : .headline)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.65)
    }

    private var currentValue: Double {
        let runningTime = startedAt.map { max(0, Date.now.timeIntervalSince($0)) } ?? 0
        let elapsed = accumulatedTime + runningTime
        return (max(0, elapsed) * max(0, hourlyRate) / 3_600 * 100).rounded() / 100
    }
}

private struct ActivityMetric<Content: View>: View {
    let title: String
    var alignment: HorizontalAlignment = .leading
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            content
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }
}
#else
struct MoneyStopwatchLiveActivity: Widget {
    private let kind = "MoneyStopwatchLiveActivityUnavailable"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UnavailableProvider()) { _ in
            EmptyView()
        }
        .configurationDisplayName("Money Stopwatch")
        .description("Live Activities are available on supported iPhone and iPad devices.")
        .supportedFamilies([])
    }
}

private struct UnavailableEntry: TimelineEntry {
    let date: Date
}

private struct UnavailableProvider: TimelineProvider {
    func placeholder(in context: Context) -> UnavailableEntry {
        UnavailableEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (UnavailableEntry) -> Void) {
        completion(UnavailableEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UnavailableEntry>) -> Void) {
        completion(Timeline(entries: [UnavailableEntry(date: .now)], policy: .never))
    }
}
#endif
