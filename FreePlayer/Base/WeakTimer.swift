//
//  WeakTimer.swift
//  JimuMagnetic
//
//  Created by CXY on 2019/3/21.
//  Copyright © 2019年 ubt. All rights reserved.
//

import UIKit

class WeakTimer: NSObject {
    
    private weak var timer: Timer?
    private weak var target: NSObject?
    private var selector: Selector?

    static func scheduledWeakTimer(timeInterval: TimeInterval, target: NSObject, selector: Selector, userInfo: Dictionary<String, Any>?, repeats: Bool) -> Timer {
        let weakTimer = WeakTimer()
        weakTimer.timer = Timer.scheduledTimer(timeInterval: timeInterval, target: weakTimer, selector: #selector(fire(_:)), userInfo: userInfo, repeats: repeats)
        weakTimer.selector = selector
        weakTimer.target = target
        return weakTimer.timer!
    }
    
    @objc func fire(_ timer: Timer) {
        guard let _target = target, let _selector = selector else {
            timer.invalidate()
            return
        }
        if _target.responds(to: _selector) {
            _target.perform(_selector, with: timer)
        } else {
            timer.invalidate()
        }
    }
    
    deinit {
        print("WeakTimer dealloc")
    }
}
