import CoreData
import Foundation
import Testing
@testable import Money_Stopwatch

struct TimerDomainTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000)

    @Test func `Timer starts, pauses, and resumes deterministically`() {
        var timer = TimerSnapshot.empty

        timer.start(hourlyRate: 60, at: start)
        #expect(timer.elapsed(at: start.addingTimeInterval(90)) == 90)

        timer.pause(at: start.addingTimeInterval(90))
        #expect(timer.elapsed(at: start.addingTimeInterval(300)) == 90)

        timer.start(hourlyRate: 999, at: start.addingTimeInterval(300))
        #expect(timer.hourlyRate == 60)
        #expect(timer.elapsed(at: start.addingTimeInterval(330)) == 120)
    }

    @Test func `Earnings include all participants and round to cents`() {
        let value = MoneyMath.earnings(
            seconds: 3_600,
            hourlyRate: 19.995,
            participantCount: 20
        )

        #expect(value == Decimal(string: "399.90"))
    }

    @Test func `Invalid rates and participant counts are bounded`() {
        #expect(MoneyMath.validatedRate(-10) == 0)
        #expect(MoneyMath.validatedRate(.infinity) == 0)
        #expect(MoneyMath.validatedRate(2_000_000) == MoneyMath.maximumHourlyRate)
        #expect(MoneyMath.earnings(seconds: 3_600, hourlyRate: 10, participantCount: 0) == 10)
    }

    @Test func `Clock rollback never creates negative elapsed time`() {
        var timer = TimerSnapshot.empty
        timer.start(hourlyRate: 20, at: start)

        #expect(timer.elapsed(at: start.addingTimeInterval(-60)) == 0)
    }

    @Test func reset() {
        var timer = TimerSnapshot(
            accumulatedTime: 42,
            startedAt: start,
            hourlyRate: 100
        )

        timer.reset()

        #expect(timer == .empty)
    }

    @MainActor
    @Test func `Running session restores from persisted state`() throws {
        let suiteName = "TimerTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstTimer = SessionTimer(defaults: defaults)
        firstTimer.toggle(hourlyRate: 75, at: start)

        let restoredTimer = SessionTimer(defaults: defaults)
        #expect(restoredTimer.isRunning)
        #expect(restoredTimer.snapshot.hourlyRate == 75)
        #expect(restoredTimer.elapsed(at: start.addingTimeInterval(120)) == 120)
    }

    @MainActor
    @Test func `Paused session restores accumulated time`() throws {
        let suiteName = "TimerTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstTimer = SessionTimer(defaults: defaults)
        firstTimer.toggle(hourlyRate: 50, at: start)
        firstTimer.pause(at: start.addingTimeInterval(45))

        let restoredTimer = SessionTimer(defaults: defaults)
        #expect(!restoredTimer.isRunning)
        #expect(restoredTimer.elapsed(at: start.addingTimeInterval(500)) == 45)
    }
}

struct TransferArchiveTests {
    @MainActor
    @Test func `Archive survives a JSON round trip`() throws {
        let fixture = try makeDefaults()
        let defaults = fixture.defaults
        defer { defaults.removePersistentDomain(forName: fixture.suiteName) }

        defaults.set(42.5, forKey: "UserRate")
        defaults.set(88_000.0, forKey: "AnnualSalary")
        defaults.set(1_920.0, forKey: "AnnualWorkingHours")
        defaults.set(false, forKey: "PlayfulLanguage")

        let persistence = PersistenceController(inMemory: true)
        let expectedID = UUID()
        insertEntry(id: expectedID, into: persistence.container.viewContext)

        let entries = try persistence.container.viewContext.fetch(TimeEntry.fetchRequest())
        let archive = MoneyStopwatchArchive(entries: entries, defaults: defaults)
        let data = try JSONEncoder().encode(archive)
        let decoded = try JSONDecoder().decode(MoneyStopwatchArchive.self, from: data)
        let decodedSettings = try #require(decoded.settings)

        try decoded.validate()
        #expect(decoded.schemaVersion == MoneyStopwatchArchive.currentSchemaVersion)
        #expect(decoded.entries.map(\.id) == [expectedID])
        #expect(decodedSettings.hourlyRate == 42.5)
        #expect(decodedSettings.annualSalary == 88_000)
        #expect(decodedSettings.annualWorkingHours == 1_920)
        #expect(decodedSettings.playfulLanguage == false)
    }

    @MainActor
    @Test func `Merge skips duplicates and replace removes local history`() throws {
        let sourceFixture = try makeDefaults()
        let destinationFixture = try makeDefaults()
        let sourceDefaults = sourceFixture.defaults
        let destinationDefaults = destinationFixture.defaults
        defer {
            sourceDefaults.removePersistentDomain(forName: sourceFixture.suiteName)
            destinationDefaults.removePersistentDomain(forName: destinationFixture.suiteName)
        }

        sourceDefaults.set(75.0, forKey: "UserRate")
        sourceDefaults.set(120_000.0, forKey: "AnnualSalary")
        sourceDefaults.set(2_000.0, forKey: "AnnualWorkingHours")
        sourceDefaults.set(true, forKey: "PlayfulLanguage")

        let source = PersistenceController(inMemory: true)
        let transferredID = UUID()
        insertEntry(id: transferredID, into: source.container.viewContext)
        let sourceEntries = try source.container.viewContext.fetch(TimeEntry.fetchRequest())
        let archive = MoneyStopwatchArchive(entries: sourceEntries, defaults: sourceDefaults)

        let destination = PersistenceController(inMemory: true)
        insertEntry(id: UUID(), into: destination.container.viewContext)

        let firstMerge = try archive.apply(
            mode: .merge,
            to: destination.container.viewContext,
            defaults: destinationDefaults
        )
        #expect(firstMerge == .init(importedCount: 1, skippedCount: 0))

        let secondMerge = try archive.apply(
            mode: .merge,
            to: destination.container.viewContext,
            defaults: destinationDefaults
        )
        #expect(secondMerge == .init(importedCount: 0, skippedCount: 1))

        let replacement = try archive.apply(
            mode: .replace,
            to: destination.container.viewContext,
            defaults: destinationDefaults
        )
        let remaining = try destination.container.viewContext.fetch(TimeEntry.fetchRequest())
        #expect(replacement == .init(importedCount: 1, skippedCount: 0))
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == transferredID)
        #expect(destinationDefaults.double(forKey: "UserRate") == 75)
        #expect(destinationDefaults.double(forKey: "AnnualSalary") == 120_000)
        #expect(destinationDefaults.double(forKey: "AnnualWorkingHours") == 2_000)
        #expect(destinationDefaults.bool(forKey: "PlayfulLanguage"))
    }

    @MainActor
    private func insertEntry(id: UUID, into context: NSManagedObjectContext) {
        let entry = TimeEntry(context: context)
        entry.id = id
        entry.category = .meeting
        entry.currencyCode = "USD"
        entry.date = Date(timeIntervalSinceReferenceDate: 1_000)
        entry.elapsed = 3_600
        entry.participantCount = 2
        entry.rate = 50
        entry.value = 100
    }

    private func makeDefaults() throws -> (suiteName: String, defaults: UserDefaults) {
        let suiteName = "TransferArchiveTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        return (suiteName, defaults)
    }
}
