import Foundation

enum HapticZone: Equatable {
    case none
    case gentle
    case medium
    case strong

    static func zone(for deficit: Double) -> HapticZone {
        switch deficit {
        case ..<1.0:
            return .none
        case ..<5:
            return .gentle
        case ..<12:
            return .medium
        default:
            return .strong
        }
    }

    var interval: TimeInterval {
        switch self {
        case .none:
            return 0
        case .gentle:
            return 0.75
        case .medium:
            return 0.5
        case .strong:
            return 0.33
        }
    }

    var intensity: Float {
        switch self {
        case .none:
            return 0
        case .gentle:
            return 0.75
        case .medium:
            return 0.90
        case .strong:
            return 1.0
        }
    }

    var sharpness: Float {
        switch self {
        case .none:
            return 0
        case .gentle:
            return 0.55
        case .medium:
            return 0.75
        case .strong:
            return 1.0
        }
    }

    var label: String {
        switch self {
        case .none:
            return "On target"
        case .gentle:
            return "Slightly upright"
        case .medium:
            return "Too upright"
        case .strong:
            return "Bend deeper"
        }
    }
}
