import CoreData
import CoreTransferable
import Foundation
import Observation
import UniformTypeIdentifiers

extension UTType {
    static let moneyStopwatchArchive = UTType(exportedAs: "anything.timer.moneystopwatcharchive")
}

struct MoneyStopwatchArchive: Codable, Sendable, Transferable {
    static let currentSchemaVersion = 2

    let schemaVersion: Int
    let exportedAt: Date
    let settings: Settings?
    let entries: [Entry]

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .moneyStopwatchArchive)
    }

    init(entries: [TimeEntry], defaults: UserDefaults = .standard) {
        schemaVersion = Self.currentSchemaVersion
        exportedAt = .now
        settings = Settings(defaults: defaults)
        self.entries = entries.compactMap(Entry.init)
    }

    init?(entry: TimeEntry) {
        guard let entry = Entry(entry: entry) else {
            return nil
        }
        schemaVersion = Self.currentSchemaVersion
        exportedAt = .now
        settings = nil
        entries = [entry]
    }

    func validate() throws {
        guard (1...Self.currentSchemaVersion).contains(schemaVersion) else {
            throw ArchiveError.unsupportedVersion(schemaVersion)
        }
        guard entries.count <= 100_000 else {
            throw ArchiveError.tooManyEntries
        }
        if let settings {
            guard settings.hourlyRate.isFinite,
                  settings.annualSalary.isFinite,
                  settings.annualWorkingHours.isFinite else {
                throw ArchiveError.invalidData
            }
        }
        guard entries.allSatisfy(\.isValid) else {
            throw ArchiveError.invalidData
        }
    }
}

extension MoneyStopwatchArchive {
    struct Settings: Codable, Sendable {
        let hourlyRate: Double
        let annualSalary: Double
        let annualWorkingHours: Double
        let playfulLanguage: Bool

        init(defaults: UserDefaults) {
            hourlyRate = defaults.double(forKey: "UserRate")
            annualSalary = defaults.double(forKey: "AnnualSalary")
            annualWorkingHours = defaults.double(forKey: "AnnualWorkingHours")
            playfulLanguage = defaults.bool(forKey: "PlayfulLanguage")
        }

        func apply(to defaults: UserDefaults) {
            defaults.set(MoneyMath.validatedRate(hourlyRate), forKey: "UserRate")
            defaults.set(max(0, annualSalary), forKey: "AnnualSalary")
            defaults.set(max(1, annualWorkingHours), forKey: "AnnualWorkingHours")
            defaults.set(playfulLanguage, forKey: "PlayfulLanguage")
        }
    }

    struct Entry: Codable, Sendable {
        let id: UUID
        let categoryRawValue: String?
        let comment: String?
        let currencyCode: String?
        let date: Date?
        let elapsed: Int64
        let endDate: Date?
        let participantCount: Int64
        let rate: Double
        let startDate: Date?
        let title: String?
        let value: Double

        init?(entry: TimeEntry) {
            guard let id = entry.id else {
                return nil
            }
            self.id = id
            categoryRawValue = entry.categoryRawValue
            comment = entry.comment
            currencyCode = entry.currencyCode
            date = entry.date
            elapsed = entry.elapsed
            endDate = entry.endDate
            participantCount = entry.participantCount
            rate = entry.rate
            startDate = entry.startDate
            title = entry.title
            value = entry.value
        }

        var isValid: Bool {
            elapsed >= 0 && participantCount >= 0 && rate.isFinite && rate >= 0
                && value.isFinite && value >= 0
        }

        func insert(into context: NSManagedObjectContext) {
            let entry = TimeEntry(context: context)
            entry.id = id
            entry.categoryRawValue = categoryRawValue
            entry.comment = comment
            entry.currencyCode = currencyCode
            entry.date = date
            entry.elapsed = elapsed
            entry.endDate = endDate
            entry.participantCount = max(1, participantCount)
            entry.rate = MoneyMath.validatedRate(rate)
            entry.startDate = startDate
            entry.title = title
            entry.value = value
        }
    }
}

struct TransferNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

@MainActor
@Observable
final class TransferInbox {
    var pendingArchive: MoneyStopwatchArchive?
    var notice: TransferNotice?

    func receive(_ result: Result<URL, any Error>) {
        do {
            let url = try result.get()
            let hasSecurityAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let archive = try JSONDecoder().decode(MoneyStopwatchArchive.self, from: data)
            try archive.validate()
            pendingArchive = archive
        } catch {
            notice = TransferNotice(
                title: "Couldn’t Read Transfer",
                message: error.localizedDescription
            )
        }
    }

    func applyPendingArchive(
        mode: MoneyStopwatchArchive.ImportMode,
        to context: NSManagedObjectContext
    ) {
        guard let archive = pendingArchive else {
            return
        }

        do {
            let result = try archive.apply(mode: mode, to: context)
            pendingArchive = nil
            let skippedDescription = result.skippedCount == 0
                ? ""
                : " \(result.skippedCount) duplicate sessions were skipped."
            notice = TransferNotice(
                title: "Transfer Complete",
                message: "Imported \(result.importedCount) sessions.\(skippedDescription)"
            )
        } catch {
            notice = TransferNotice(
                title: "Couldn’t Import Transfer",
                message: error.localizedDescription
            )
        }
    }
}

extension MoneyStopwatchArchive {
    enum ImportMode {
        case merge
        case replace
    }

    struct ImportResult: Equatable {
        let importedCount: Int
        let skippedCount: Int
    }

    @MainActor
    func apply(
        mode: ImportMode,
        to context: NSManagedObjectContext,
        defaults: UserDefaults = .standard
    ) throws -> ImportResult {
        try validate()

        let request = TimeEntry.fetchRequest()
        let existingEntries = try context.fetch(request)
        let existingIDs = Set(existingEntries.compactMap(\.id))

        if mode == .replace {
            existingEntries.forEach(context.delete)
        }

        var importedCount = 0
        var skippedCount = 0
        for record in entries {
            if mode == .merge && existingIDs.contains(record.id) {
                skippedCount += 1
                continue
            }
            record.insert(into: context)
            importedCount += 1
        }

        do {
            try context.save()
            settings?.apply(to: defaults)
            return ImportResult(importedCount: importedCount, skippedCount: skippedCount)
        } catch {
            context.rollback()
            throw error
        }
    }
}

extension MoneyStopwatchArchive {
    enum ArchiveError: LocalizedError {
        case invalidData
        case tooManyEntries
        case unsupportedVersion(Int)

        var errorDescription: String? {
            switch self {
            case .invalidData:
                "The transfer file contains invalid data."
            case .tooManyEntries:
                "The transfer file contains too many sessions."
            case .unsupportedVersion(let version):
                "This transfer file uses unsupported format version \(version)."
            }
        }
    }
}
