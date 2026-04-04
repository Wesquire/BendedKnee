import Foundation

struct AppSettings: Equatable {
    static let targetRange: ClosedRange<Double> = 0...60
    static let volumeRange: ClosedRange<Double> = 0...1

    var pocketSide: PocketSide = .frontLeft
    var targetAngle: Double = 20
    var pulseVolume: Double = 0.6
    var hapticsEnabled: Bool = true
}
