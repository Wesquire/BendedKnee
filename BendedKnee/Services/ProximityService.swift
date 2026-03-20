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
        ) { _ in
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
    private var handler: ((Bool) -> Void)?

    init(mode: Mode = .steadyNear) {
        self.mode = mode
    }

    var isSupported: Bool { true }
    var currentState: Bool = true

    func start(handler: @escaping (Bool) -> Void) {
        scheduledChange?.cancel()
        scheduledChange = nil
        currentState = true
        self.handler = handler
        handler(currentState)
        if case .autoRemove(let delay) = mode {
            let workItem = DispatchWorkItem { [weak self] in
                self?.emit(false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                    guard self?.currentState == false else { return }
                    self?.handler?(false)
                }
            }
            scheduledChange = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }

    func stop() {
        scheduledChange?.cancel()
        scheduledChange = nil
        currentState = true
        handler = nil
    }

    private func emit(_ isNear: Bool) {
        currentState = isNear
        handler?(isNear)
    }
}
