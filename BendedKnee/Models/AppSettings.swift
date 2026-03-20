import Foundation

struct AppSettings: Equatable {
    static let targetRange: ClosedRange<Double> = 0...60

    var targetAngle: Double = 20
}
