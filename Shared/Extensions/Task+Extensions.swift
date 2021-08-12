//
//  Task+Extensions.swift
//  Task+Extensions
//
//  Created by Martin Young on 8/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A thread safe collection of tasks.
/// This allows for bulk-cancelling multiple tasks.
actor TaskPool {

    private var pool: [Task<Void, Never>] = []

    /// Adds a task to the pool.
    func add(_ task: Task<Void, Never>) {
        self.pool.append(task)
    }

    /// Removes a task from the pool.
    func remove(_ task: Task<Void, Never>) {
        self.pool.remove(object: task)
    }

    /// Cancels all tasks currently in the pool.
    func cancelAndRemoveAll() {
        for task in self.pool {
            task.cancel()
        }
        self.pool.removeAll()
    }
}

extension Task where Success == Void, Failure == Never {

    /// Adds the task to the given task pool. Once the task is finished, the task is removed from the pool.
    func add(to taskPool: TaskPool) {
        Task {
            await taskPool.add(self)
            _ = await self.result
            await taskPool.remove(self)
        }
    }
}

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
