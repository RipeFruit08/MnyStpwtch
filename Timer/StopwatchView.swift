import CoreData
import SwiftUI

struct StopwatchView: View {
    @Environment(\.managedObjectContext) private var context
    @AppStorage("UserRate") private var configuredHourlyRate = 19.0
    @AppStorage("PlayfulLanguage") private var playfulLanguage = true

    let timer: SessionTimer

    @State private var showingSaveSheet = false
    @State private var resumeAfterCancellation = false
    @State private var category = SessionCategory.companyTime
    @State private var sessionTitle = ""
    @State private var comment = ""
    @State private var participantCount = 1
    @State private var saveError: String?

    var body: some View {
        Group {
            if timer.isRunning {
                TimelineView(.periodic(from: .now, by: 0.05)) { timeline in
                    StopwatchDisplay(
                        elapsed: timer.elapsed(at: timeline.date),
                        earnings: timer.earnings(at: timeline.date),
                        hourlyRate: timer.snapshot.hourlyRate,
                        isRunning: true,
                        toggle: { timer.toggle(hourlyRate: configuredHourlyRate, at: timeline.date) },
                        reset: timer.reset,
                        save: { prepareToSave(at: timeline.date) }
                    )
                }
            } else {
                let now = Date()
                StopwatchDisplay(
                    elapsed: timer.elapsed(at: now),
                    earnings: timer.earnings(at: now),
                    hourlyRate: timer.snapshot.accumulatedTime > 0
                        ? timer.snapshot.hourlyRate
                        : MoneyMath.validatedRate(configuredHourlyRate),
                    isRunning: false,
                    toggle: { timer.toggle(hourlyRate: configuredHourlyRate, at: Date()) },
                    reset: timer.reset,
                    save: { prepareToSave(at: Date()) }
                )
            }
        }
        .navigationTitle("Money Stopwatch")
        .sheet(isPresented: $showingSaveSheet) {
            saveSheet
        }
        .alert("Couldn’t Save", isPresented: saveErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }

    private var saveSheet: some View {
        SaveSessionSheet(
            snapshot: timer.snapshot,
            playfulLanguage: playfulLanguage,
            currencyCode: currencyCode,
            category: $category,
            sessionTitle: $sessionTitle,
            comment: $comment,
            participantCount: $participantCount,
            cancel: cancelSave,
            save: saveSession
        )
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )
    }

    private func prepareToSave(at date: Date) {
        resumeAfterCancellation = timer.isRunning
        if timer.isRunning {
            timer.pause(at: date)
        }
        showingSaveSheet = true
    }

    private func cancelSave() {
        showingSaveSheet = false
        if resumeAfterCancellation {
            timer.toggle(hourlyRate: timer.snapshot.hourlyRate, at: Date())
        }
        resumeAfterCancellation = false
    }

    private func saveSession() {
        let elapsed = timer.snapshot.accumulatedTime
        let endDate = Date()
        let entry = TimeEntry(context: context)
        entry.id = UUID()
        entry.category = category
        entry.title = sessionTitle.nilIfBlank
        entry.comment = comment.nilIfBlank
        entry.currencyCode = currencyCode
        entry.date = endDate
        entry.startDate = endDate.addingTimeInterval(-elapsed)
        entry.endDate = endDate
        entry.elapsed = Int64(elapsed.rounded())
        entry.participantCount = Int64(participantCount)
        entry.rate = timer.snapshot.hourlyRate
        entry.value = NSDecimalNumber(
            decimal: timer.snapshot.earnings(at: endDate, participantCount: participantCount)
        ).doubleValue

        do {
            try context.save()
            timer.reset()
            resetDraft()
            showingSaveSheet = false
        } catch {
            context.rollback()
            saveError = error.localizedDescription
        }
    }

    private func resetDraft() {
        resumeAfterCancellation = false
        category = .companyTime
        sessionTitle = ""
        comment = ""
        participantCount = 1
    }
}

private struct SaveSessionSheet: View {
    private enum Field: Hashable {
        case title
        case comment
    }

    let snapshot: TimerSnapshot
    let playfulLanguage: Bool
    let currencyCode: String
    @Binding var category: SessionCategory
    @Binding var sessionTitle: String
    @Binding var comment: String
    @Binding var participantCount: Int
    let cancel: () -> Void
    let save: () -> Void

    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    Picker("Category", selection: $category) {
                        ForEach(SessionCategory.allCases) { category in
                            Label(category.title(playful: playfulLanguage), systemImage: category.systemImage)
                                .tag(category)
                        }
                    }

                    TextField("Title (optional)", text: $sessionTitle)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.done)
                        .onSubmit(dismissKeyboard)

                    Stepper("People: \(participantCount)", value: $participantCount, in: 1...1_000)

                    LabeledContent("Elapsed", value: snapshot.accumulatedTime.formattedStopwatch)
                    LabeledContent(
                        participantCount == 1 ? "Value" : "Combined value",
                        value: NSDecimalNumber(
                            decimal: snapshot.earnings(at: .now, participantCount: participantCount)
                        ).doubleValue.formatted(.currency(code: currencyCode))
                    )
                }

                Section("Note") {
                    TextField("What happened?", text: $comment, axis: .vertical)
                        .focused($focusedField, equals: .comment)
                }

                if category == .meeting && participantCount > 1 {
                    Section {
                        Text("\(participantCount) people spent a combined \(Duration.seconds(snapshot.accumulatedTime * Double(participantCount)).formatted(.units(allowed: [.hours, .minutes], width: .wide))).")
                    } header: {
                        Text(playfulLanguage ? "The meeting receipt" : "Meeting impact")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Save Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done", action: dismissKeyboard)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled()
    }

    private func dismissKeyboard() {
        focusedField = nil
    }
}

private struct StopwatchDisplay: View {
    let elapsed: TimeInterval
    let earnings: Decimal
    let hourlyRate: Double
    let isRunning: Bool
    let toggle: () -> Void
    let reset: () -> Void
    let save: () -> Void

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 8) {
                Text(elapsed.formattedStopwatch)
                    .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text(earnings.formatted(.currency(code: currencyCode)))
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contentTransition(.numericText())
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "Elapsed time \(elapsed.formattedStopwatch), value \(earnings.formatted(.currency(code: currencyCode)))"
            )

            Text("At \(hourlyRate.formatted(.currency(code: currencyCode))) per hour")
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button(isRunning ? "Pause" : "Start", systemImage: isRunning ? "pause.fill" : "play.fill", action: toggle)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                Button("Reset", systemImage: "arrow.counterclockwise", action: reset)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(elapsed == 0)
            }

            Button("Save Session", systemImage: "square.and.arrow.down", action: save)
                .disabled(elapsed == 0)

            Spacer()
        }
        .frame(maxWidth: 640)
        .padding()
        .frame(maxWidth: .infinity)
    }
}
