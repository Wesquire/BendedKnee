import Foundation

enum PocketSide: String, CaseIterable, Identifiable {
    case frontLeft = "Front Left"
    case frontRight = "Front Right"
    case backLeft = "Back Left"
    case backRight = "Back Right"

    var id: String { rawValue }

    /// Sign applied to the X (lateral) axis to normalize gravity.
    var lateralSign: Double {
        switch self {
        case .frontLeft, .backRight: return -1
        case .frontRight, .backLeft: return 1
        }
    }

    /// Sign applied to the Z (depth) axis to normalize gravity.
    /// Front pockets: screen faces thigh, Z is positive when tilting forward.
    /// Back pockets: phone is rotated 180° around Y, so Z is inverted.
    var depthSign: Double {
        switch self {
        case .frontLeft, .frontRight: return 1
        case .backLeft, .backRight: return -1
        }
    }

    var isFront: Bool {
        switch self {
        case .frontLeft, .frontRight: return true
        case .backLeft, .backRight: return false
        }
    }

    var setupDescription: String {
        switch self {
        case .frontLeft:  return "Use your left front pocket."
        case .frontRight: return "Use your right front pocket."
        case .backLeft:   return "Use your left back pocket."
        case .backRight:  return "Use your right back pocket."
        }
    }

    var shortLabel: String {
        switch self {
        case .frontLeft:  return "FL"
        case .frontRight: return "FR"
        case .backLeft:   return "BL"
        case .backRight:  return "BR"
        }
    }
}
