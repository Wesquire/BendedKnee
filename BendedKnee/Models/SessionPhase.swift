import Foundation

enum SessionPhase: Equatable {
    case onboarding
    case idle
    case calibrating(secondsRemaining: Int)
    case ready
    case running
    case pausedPocketRemoved
    case unavailable(String)
}
