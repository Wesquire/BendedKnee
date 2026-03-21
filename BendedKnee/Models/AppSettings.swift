import Foundation

struct AppSettings: Equatable {
    static let targetRange: ClosedRange<Double> = 0...60
    static let volumeRange: ClosedRange<Double> = 0...1

    var pocketSide: PocketSide = .right
    var targetAngle: Double = 20
    var pulseVolume: Double = 0.6
    var pulseAudioEnabled: Bool = true
}
