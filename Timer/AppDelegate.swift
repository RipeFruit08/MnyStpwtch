import CoreData
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "HistoryModel")
        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Unable to load the history store: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if UserDefaults.standard.object(forKey: "UserRate") == nil {
            UserDefaults.standard.set(19.0, forKey: "UserRate")
        }
        return true
    }

    func saveContext() {
        let context = persistentContainer.viewContext
        guard context.hasChanges else {
            return
        }

        do {
            try context.save()
        } catch {
            assertionFailure("Unable to save history: \(error.localizedDescription)")
        }
    }
}
