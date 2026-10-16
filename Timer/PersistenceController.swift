import CoreData
import Observation

@MainActor
@Observable
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    private(set) var errorMessage: String?

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "HistoryModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.persistentStoreDescriptions.forEach {
            $0.shouldMigrateStoreAutomatically = true
            $0.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { [weak self] _, error in
            if let error {
                Task { @MainActor in
                    self?.errorMessage = error.localizedDescription
                }
            } else {
                Task { @MainActor in
                    self?.assignMissingEntryIdentifiers()
                }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func clearError() {
        errorMessage = nil
    }

    private func assignMissingEntryIdentifiers() {
        do {
            let request = TimeEntry.fetchRequest()
            request.predicate = NSPredicate(format: "id == nil")
            let entries = try container.viewContext.fetch(request)
            guard !entries.isEmpty else {
                return
            }
            entries.forEach { $0.id = UUID() }
            try container.viewContext.save()
        } catch {
            container.viewContext.rollback()
            errorMessage = error.localizedDescription
        }
    }
}
