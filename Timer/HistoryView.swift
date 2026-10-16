import CoreData
import SwiftUI

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TimeEntry.date, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<TimeEntry>

    @State private var pendingDeletion: TimeEntry?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Saved Sessions",
                    systemImage: "clock.badge.questionmark",
                    description: Text("Saved timer sessions will appear here.")
                )
            } else {
                List {
                    Section {
                        SummaryView(
                            sessionCount: entries.count,
                            totalSeconds: entries.reduce(0) { $0 + TimeInterval($1.elapsed) },
                            totalValue: entries.reduce(0) { $0 + $1.value }
                        )
                    }

                    Section("Sessions") {
                        ForEach(entries, id: \.objectID) { entry in
                            NavigationLink {
                                HistoryDetailView(entry: entry)
                            } label: {
                                HistoryRow(entry: entry)
                            }
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    pendingDeletion = entry
                                }
                            }
                            .contextMenu {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    pendingDeletion = entry
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .confirmationDialog(
            "Delete this session?",
            isPresented: deletionConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Session", role: .destructive) {
                deletePendingEntry()
            }
            Button("Cancel", role: .cancel) {
                pendingDeletion = nil
            }
        } message: {
            Text("This can’t be undone.")
        }
        .alert("Couldn’t Update History", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var deletionConfirmation: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func deletePendingEntry() {
        guard let pendingDeletion else {
            return
        }

        context.delete(pendingDeletion)
        do {
            try context.save()
            self.pendingDeletion = nil
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
        }
    }
}

private struct SummaryView: View {
    let sessionCount: Int
    let totalSeconds: TimeInterval
    let totalValue: Double

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    var body: some View {
        HStack(spacing: 24) {
            SummaryMetric(title: "Sessions", value: sessionCount.formatted())
            SummaryMetric(title: "Time", value: totalSeconds.formattedStopwatch)
            SummaryMetric(
                title: "Value",
                value: totalValue.formatted(.currency(code: currencyCode))
            )
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

private struct SummaryMetric: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HistoryRow: View {
    @AppStorage("PlayfulLanguage") private var playfulLanguage = true

    let entry: TimeEntry

    private var displayTitle: String {
        entry.title?.nilIfBlank ?? entry.category.title(playful: playfulLanguage)
    }

    private var currencyCode: String {
        entry.currencyCode ?? Locale.current.currency?.identifier ?? "USD"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(displayTitle, systemImage: entry.category.systemImage)
                    .font(.headline)
                Spacer()
                Text(entry.value.formatted(.currency(code: currencyCode)))
                    .font(.headline)
            }

            HStack {
                Text(entry.date ?? .now, format: .dateTime.month().day().year())
                Spacer()
                Label(TimeInterval(entry.elapsed).formattedStopwatch, systemImage: "clock")
                if entry.effectiveParticipantCount > 1 {
                    Label(entry.effectiveParticipantCount.formatted(), systemImage: "person.2")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct HistoryDetailView: View {
    @AppStorage("PlayfulLanguage") private var playfulLanguage = true

    let entry: TimeEntry

    private var displayTitle: String {
        entry.title?.nilIfBlank ?? entry.category.title(playful: playfulLanguage)
    }

    private var currencyCode: String {
        entry.currencyCode ?? Locale.current.currency?.identifier ?? "USD"
    }

    private var receiptText: String {
        """
        \(displayTitle)
        Time: \(TimeInterval(entry.elapsed).formattedStopwatch)
        People: \(entry.effectiveParticipantCount)
        Value: \(entry.value.formatted(.currency(code: currencyCode)))
        """
    }

    private var sessionArchive: MoneyStopwatchArchive? {
        MoneyStopwatchArchive(entry: entry)
    }

    var body: some View {
        Form {
            Section("Session") {
                LabeledContent("Category", value: entry.category.title(playful: playfulLanguage))
                LabeledContent("Date") {
                    Text(entry.date ?? .now, format: .dateTime)
                }
                LabeledContent("Elapsed", value: TimeInterval(entry.elapsed).formattedStopwatch)
                LabeledContent(
                    "Rate",
                    value: "\(entry.rate.formatted(.currency(code: currencyCode)))/hr"
                )
                LabeledContent("People", value: entry.effectiveParticipantCount.formatted())
                LabeledContent(
                    entry.effectiveParticipantCount == 1 ? "Value" : "Combined value",
                    value: entry.value.formatted(.currency(code: currencyCode))
                )
            }

            if let comment = entry.comment?.nilIfBlank {
                Section("Note") {
                    Text(comment)
                }
            }
        }
        .navigationTitle(displayTitle)
        .toolbar {
            if let sessionArchive {
                ShareLink(
                    item: sessionArchive,
                    preview: SharePreview("Money Stopwatch Session")
                ) {
                    Label("Send Session", systemImage: "iphone.and.arrow.forward.outward")
                }
            }

            ShareLink(item: receiptText) {
                Label("Share Summary", systemImage: "square.and.arrow.up")
            }
        }
    }
}
