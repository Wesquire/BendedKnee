import Foundation

struct CalibrationAccumulator {
    private var samples: [Double] = []

    var average: Double? {
        guard !samples.isEmpty else { return nil }
        return samples.reduce(0, +) / Double(samples.count)
    }

    var spread: Double? {
        guard let minimum = samples.min(), let maximum = samples.max() else {
            return nil
        }
        return maximum - minimum
    }

    mutating func add(_ sample: Double) {
        samples.append(sample)
    }

    mutating func reset() {
        samples.removeAll(keepingCapacity: true)
    }

    func isStable(minimumSamples: Int, maximumSpread: Double) -> Bool {
        guard samples.count >= minimumSamples, let spread else {
            return false
        }
        return spread <= maximumSpread
    }
}
