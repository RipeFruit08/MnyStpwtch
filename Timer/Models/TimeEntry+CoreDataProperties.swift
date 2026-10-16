import CoreData
import Foundation

extension TimeEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimeEntry> {
        NSFetchRequest<TimeEntry>(entityName: "TimeEntry")
    }

    @NSManaged public var categoryRawValue: String?
    @NSManaged public var comment: String?
    @NSManaged public var currencyCode: String?
    @NSManaged public var date: Date?
    @NSManaged public var elapsed: Int64
    @NSManaged public var endDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var participantCount: Int64
    @NSManaged public var rate: Double
    @NSManaged public var startDate: Date?
    @NSManaged public var title: String?
    @NSManaged public var value: Double

    var category: SessionCategory {
        get {
            categoryRawValue.flatMap(SessionCategory.init(rawValue:)) ?? .custom
        }
        set {
            categoryRawValue = newValue.rawValue
        }
    }

    var effectiveParticipantCount: Int {
        max(1, Int(participantCount))
    }

    var displayTitle: String {
        title?.nilIfBlank ?? category.title
    }
}
