import Foundation

@objc
public class StatsigUpdatesHandle: NSObject {
    private(set) var isCancelled = false
    private var timer: DispatchSourceTimer
    
    init(_ timer: DispatchSourceTimer) {
        self.timer = timer
    }
    
    @objc
    public func cancel() {
        guard !isCancelled else {
            return
        }
        
        isCancelled = true
        timer.cancel()
    }
}
