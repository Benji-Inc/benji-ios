//
//  Task+Extensions.swift
//  Task+Extensions
//
//  Created by Martin Young on 8/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension Task where Success == Void, Failure == Never {

    /// Creates a new task that runs the passed in closure on the MainActor. For use in non-async functions.
    static func onMainActor(body: @escaping @MainActor @Sendable () -> Success) {
        Task {
            await MainActor.run {
                body()
            }
        }
    }

    /// Creates a new task that runs the passed in closure on the MainActor. For use in async functions.
    static func onMainActorAsync(body: @escaping @MainActor @Sendable () -> Success) async {
        await MainActor.run {
            body()
        }
    }
}

extension Task where Success == Never, Failure == Never {

    /// Suspends the current task for _at least_ the given duration
    /// in seconds.
    static func sleep(seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    /// Temporarily suspends the current task for at least the specified number of seconds.
    /// Unlike Task.sleep, this function will unsuspend early if the task is cancelled.
    /// By default it checks to see if the task is cancelled every "cancelInterval" number of seconds.
    static func snooze(seconds: TimeInterval, cancelInterval: Double = 0.01) async {
        let duration = UInt64(seconds * 1_000_000_000)
        let target = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW) + duration

        repeat {
            await Task.sleep(seconds: cancelInterval)
            if Task.isCancelled {
                break
            }
        } while clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW) < target
    }
}
