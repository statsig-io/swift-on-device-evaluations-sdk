import Foundation

extension Statsig {
    internal func subscribeToApplicationLifecycle() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillBackground),
            name: LifecycleNotif.MoveToBackground,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: LifecycleNotif.Terminated,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillForeground),
            name: LifecycleNotif.MoveToForeground,
            object: nil)
    }

    internal func unsubscribeFromApplicationLifecycle() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appWillForeground() {
        logger.start()
    }

    @objc private func appWillBackground() {
        DispatchQueue.global().async { [weak self] in
            self?.logger.flush()
        }
    }

    @objc private func appWillTerminate() {
        logger.flush()
    }
}


#if canImport(UIKit)
import UIKit

enum LifecycleNotif {
    static let MoveToBackground = UIApplication.willResignActiveNotification
    static let Terminated = UIApplication.willTerminateNotification
    static let MoveToForeground = UIApplication.willEnterForegroundNotification
}

#elseif canImport(AppKit)
import AppKit

enum LifecycleNotif {
    static let MoveToBackground = NSApplication.willResignActiveNotification
    static let Terminated = NSApplication.willTerminateNotification
    static let MoveToForeground = NSApplication.willBecomeActiveNotification
}

#endif
