//
//  Task+Extensions.swift
//  Task+Extensions
//
//  Created by Martin Young on 8/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension Task where Success == Never, Failure == Never {

    /// Temporarily suspends the current task for at least the specified number of seconds.
    /// Unlike Task.sleep, this function will unsuspend early if the task is cancelled.
    /// By default it checks to see if the task is cancelled every "cancelInterval" number of seconds.
    static func snooze(seconds: Double, cancelInterval: Double = 0.01) async {

        let duration = UInt64(seconds * 1_000_000_000)
        let target = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW) + duration

        repeat {
            await Task.sleep(UInt64(cancelInterval * 1_000_000_000))
            if Task.isCancelled {
                print("==== sleep was cancelled")
                break
            }
        } while clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW) < target
    }
}
