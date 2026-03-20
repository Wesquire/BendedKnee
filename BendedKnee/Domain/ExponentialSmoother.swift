import Foundation

struct ExponentialSmoother {
    let alpha: Double
    private(set) var value: Double?

    init(alpha: Double = 0.25) {
        self.alpha = alpha
    }

    mutating func add(_ sample: Double) -> Double {
        guard let value else {
            self.value = sample
            return sample
        }

        let next = value + alpha * (sample - value)
        self.value = next
        return next
    }

    mutating func reset() {
        value = nil
    }
}
