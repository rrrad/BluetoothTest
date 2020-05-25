//
//  Countdown.swift
//  BluetoothTest
//
//  Created by Radislav Gaynanov on 24.05.2020.
//  Copyright © 2020 Radislav Gaynanov. All rights reserved.
//

import Foundation

class Countdown {
    let timer: Timer
    
    init(seconds: TimeInterval, closure: @escaping()->Void) {
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { _ in
            if seconds != 0 {
                closure()
            }
        })
    }
    
    deinit {
        timer.invalidate()
    }
}
