import CoreData
import SwiftUI

@main
struct MoneyStopwatchApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(\.managedObjectContext, appDelegate.persistentContainer.viewContext)
        }
    }
}

private struct AppView: View {
    var body: some View {
        TabView {
            Tab("Timer", systemImage: "stopwatch") {
                NavigationStack {
                    StopwatchView()
                }
            }

            Tab("History", systemImage: "clock.arrow.circlepath") {
                NavigationStack {
                    HistoryView()
                }
            }

            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

private struct StopwatchView: View {
    @Environment(\.managedObjectContext) private var context
    @AppStorage("UserRate") private var hourlyRate = 19.0

    @State private var accumulatedTime: TimeInterval = 0
    @State private var startedAt: Date?
    @State private var showingSaveSheet = false
    @State private var comment = ""
    @State private var saveError: String?

    private var isRunning: Bool {
        startedAt != nil
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { timeline in
            let elapsed = elapsedTime(at: timeline.date)

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 8) {
                    Text(elapsed.formattedStopwatch)
                        .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Text((elapsed * hourlyRate / 3_600).formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Elapsed time \(elapsed.formattedStopwatch), earnings \((elapsed * hourlyRate / 3_600).formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")

                Text("At \(hourlyRate.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))) per hour")
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    Button(isRunning ? "Pause" : "Start", systemImage: isRunning ? "pause.fill" : "play.fill") {
                        toggleTimer(at: timeline.date)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Reset", systemImage: "arrow.counterclockwise") {
                        accumulatedTime = 0
                        startedAt = nil
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(elapsed == 0)
                }

                Button("Save Session", systemImage: "square.and.arrow.down") {
                    if isRunning {
                        toggleTimer(at: timeline.date)
                    }
                    showingSaveSheet = true
                }
                .disabled(elapsed == 0)

                Spacer()
            }
            .frame(maxWidth: 640)
            .padding()
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Money Stopwatch")
        .sheet(isPresented: $showingSaveSheet) {
            NavigationStack {
                Form {
                    Section("Session") {
                        LabeledContent("Elapsed", value: accumulatedTime.formattedStopwatch)
                        LabeledContent(
                            "Earned",
                            value: (accumulatedTime * hourlyRate / 3_600)
                                .formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
                        )
                    }

                    Section("Comment") {
                        TextField("Optional note", text: $comment, axis: .vertical)
                    }
                }
                .navigationTitle("Save Session")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingSaveSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveSession()
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Couldn’t Save", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }

    private func elapsedTime(at date: Date) -> TimeInterval {
        accumulatedTime + (startedAt.map { date.timeIntervalSince($0) } ?? 0)
    }

    private func toggleTimer(at date: Date) {
        if let startedAt {
            accumulatedTime += date.timeIntervalSince(startedAt)
            self.startedAt = nil
        } else {
            startedAt = date
        }
    }

    private func saveSession() {
        let entry = TimeEntry(context: context)
        entry.date = Date() as NSDate
        entry.elapsed = Int64(accumulatedTime.rounded())
        entry.rate = hourlyRate
        entry.value = (accumulatedTime * hourlyRate / 3_600 * 100).rounded() / 100
        entry.comment = comment.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        do {
            try context.save()
            accumulatedTime = 0
            comment = ""
            showingSaveSheet = false
        } catch {
            context.rollback()
            saveError = error.localizedDescription
        }
    }
}

private struct HistoryView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TimeEntry.date, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<TimeEntry>

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
                    ForEach(entries, id: \.objectID) { entry in
                        NavigationLink {
                            HistoryDetailView(entry: entry)
                        } label: {
                            HistoryRow(entry: entry)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle("History")
    }

    private func delete(at offsets: IndexSet) {
        offsets.map { entries[$0] }.forEach(context.delete)
        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }
}

private struct HistoryRow: View {
    let entry: TimeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.value.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                    .font(.headline)
                Spacer()
                Text((entry.date as Date? ?? .now), format: .dateTime.month().day().year())
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label(TimeInterval(entry.elapsed).formattedStopwatch, systemImage: "clock")
                Spacer()
                Text("\(entry.rate.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))/hr")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct HistoryDetailView: View {
    let entry: TimeEntry

    var body: some View {
        Form {
            Section("Session") {
                LabeledContent("Date") {
                    Text((entry.date as Date? ?? .now), format: .dateTime)
                }
                LabeledContent("Elapsed", value: TimeInterval(entry.elapsed).formattedStopwatch)
                LabeledContent(
                    "Rate",
                    value: "\(entry.rate.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))/hr"
                )
                LabeledContent(
                    "Earned",
                    value: entry.value.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
                )
            }

            if let comment = entry.comment?.nilIfEmpty {
                Section("Comment") {
                    Text(comment)
                }
            }
        }
        .navigationTitle("Session")
    }
}

private struct SettingsView: View {
    @AppStorage("UserRate") private var hourlyRate = 19.0

    var body: some View {
        Form {
            Section {
                LabeledContent("Hourly rate") {
                    TextField("Rate", value: $hourlyRate, format: .number.precision(.fractionLength(2)))
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 100, maxWidth: 180)
#if !targetEnvironment(macCatalyst)
                        .keyboardType(.decimalPad)
#endif
                }
            } header: {
                Text("Earnings")
            } footer: {
                Text("The rate is stored on this device and is applied when a session is saved.")
            }

            Section("Appearance") {
                Text("Money Stopwatch follows your system appearance automatically.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}

private extension TimeInterval {
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

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
