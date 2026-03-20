import Foundation
import UIKit

protocol ProximityMonitoring {
    var isSupported: Bool { get }
    var currentState: Bool { get }
    func start(handler: @escaping (Bool) -> Void)
    func stop()
}

final class ProximityService: ProximityMonitoring {
    private var observer: NSObjectProtocol?
    private var handler: ((Bool) -> Void)?

    var isSupported: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    var currentState: Bool {
        UIDevice.current.proximityState
    }

    func start(handler: @escaping (Bool) -> Void) {
        self.handler = handler
        guard isSupported else {
            return
        }

        UIDevice.current.isProximityMonitoringEnabled = true
        observer = NotificationCenter.default.addObserver(
            forName: UIDevice.proximityStateDidChangeNotification,
            object: UIDevice.current,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            handler(UIDevice.current.proximityState)
        }
        handler(UIDevice.current.proximityState)
    }

    func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
        UIDevice.current.isProximityMonitoringEnabled = false
        handler = nil
    }
}

final class PreviewProximityService: ProximityMonitoring {
    enum Mode {
        case steadyNear
        case autoRemove(after: TimeInterval)
    }

    private let mode: Mode
    private var scheduledChange: DispatchWorkItem?

    init(mode: Mode = .steadyNear) {
        self.mode = mode
    }

    var isSupported: Bool { true }
    var currentState: Bool = true

    func start(handler: @escaping (Bool) -> Void) {
        handler(currentState)
        if case .autoRemove(let delay) = mode {
            let workItem = DispatchWorkItem { [weak self] in
                self?.currentState = false
                handler(false)
            }
            scheduledChange = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }

    func stop() {
        scheduledChange?.cancel()
        scheduledChange = nil
    }
}
