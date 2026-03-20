import Foundation

enum PocketSide: String, CaseIterable, Identifiable {
    case left = "Left"
    case right = "Right"

    var id: String { rawValue }

    var lateralSign: Double {
        switch self {
        case .left:
            return -1
        case .right:
            return 1
        }
    }

    var setupDescription: String {
        switch self {
        case .left:
            return "Use your left front pocket."
        case .right:
            return "Use your right front pocket."
        }
    }
}
