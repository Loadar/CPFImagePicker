//
//  Throttler.swift
//  
//
//  Created by Aaron on 2022/12/12.
//

import UIKit

public class Throttler {
    /// 运行队列
    private let queue = DispatchQueue.global(qos: .background)
    /// 执行任务
    private var job: DispatchWorkItem?
    /// 上次运行时刻
    private var previousRunDate = Date.distantPast
    /// 最大时间间隔，单位秒
    fileprivate let maxInterval: TimeInterval
    
    /// 线程同步信号量
    private let semaphore: DispatchSemaphore
    
    init(_ maxInterval: TimeInterval) {
        self.maxInterval = maxInterval
        self.semaphore = .init(value: 1)
    }
    
    public func run(onMainThread: Bool = true, _ action: @escaping () -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.semaphore.wait()
            
            self.job?.cancel()
            let newJob = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.previousRunDate = Date()

                if onMainThread {
                    DispatchQueue.main.async {
                        action()
                    }
                } else {
                    action()
                }
            }
            self.job = newJob
            let deadline = Date().timeIntervalSince(self.previousRunDate) >= self.maxInterval ? 0 : self.maxInterval
            self.queue.asyncAfter(deadline: .now() + deadline, execute: newJob)
            self.semaphore.signal()
        }
    }
}

extension UIView {
    private struct CPFThrottlerConfig {
        static var id = 0
    }
    
    /// 节流器
    var cpf_Throttler: Throttler? {
        get {
            objc_getAssociatedObject(self, &CPFThrottlerConfig.id) as? Throttler
        }
        set {
            objc_setAssociatedObject(self, &CPFThrottlerConfig.id, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func cpfThrottler(maxInterval: TimeInterval = 0.2) -> Throttler {
        if let throttler = cpf_Throttler, throttler.maxInterval == maxInterval {
            return throttler
        } else {
            let throttler = Throttler(maxInterval)
            self.cpf_Throttler = throttler
            return throttler
        }
    }
}
