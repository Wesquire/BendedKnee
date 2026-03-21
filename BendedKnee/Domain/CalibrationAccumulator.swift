import Foundation

struct CalibrationAccumulator {
    private var samples: [Double] = []

    var average: Double? {
        let stableSamples = trimmedSamples
        guard !stableSamples.isEmpty else { return nil }
        return stableSamples.reduce(0, +) / Double(stableSamples.count)
    }

    var spread: Double? {
        let stableSamples = trimmedSamples
        guard let minimum = stableSamples.min(), let maximum = stableSamples.max() else {
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

    private var trimmedSamples: [Double] {
        guard samples.count >= 5 else { return samples }
        let sorted = samples.sorted()
        let trimCount = max(1, Int(Double(sorted.count) * 0.1))
        guard trimCount * 2 < sorted.count else { return samples }
        return Array(sorted.dropFirst(trimCount).dropLast(trimCount))
    }
}
