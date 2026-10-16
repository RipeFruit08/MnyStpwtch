import Foundation

enum SessionCategory: String, CaseIterable, Identifiable {
    case companyTime
    case meeting
    case bathroomBreak
    case waiting
    case commute
    case distraction
    case custom

    var id: Self { self }

    var title: String {
        title(playful: true)
    }

    func title(playful: Bool) -> String {
        switch (self, playful) {
        case (.companyTime, true): "Company Time"
        case (.meeting, true): "This Could’ve Been an Email"
        case (.bathroomBreak, true): "Bathroom Break"
        case (.waiting, true): "Waiting Around"
        case (.commute, true): "Commute"
        case (.distraction, true): "Doomscrolling"
        case (.custom, true): "Custom"
        case (.companyTime, false): "Work Session"
        case (.meeting, false): "Meeting"
        case (.bathroomBreak, false): "Personal Break"
        case (.waiting, false): "Waiting"
        case (.commute, false): "Commute"
        case (.distraction, false): "Distraction"
        case (.custom, false): "Custom"
        }
    }

    var systemImage: String {
        switch self {
        case .companyTime: "briefcase"
        case .meeting: "person.3"
        case .bathroomBreak: "toilet"
        case .waiting: "hourglass"
        case .commute: "car"
        case .distraction: "iphone"
        case .custom: "tag"
        }
    }
}
