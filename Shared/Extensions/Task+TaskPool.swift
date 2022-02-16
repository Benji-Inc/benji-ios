//
//  Task+TaskPool.swift
//  Task+TaskPool
//
//  Created by Martin Young on 8/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A collection of tasks that automatically handles removing tasks from itself when the tasks finish.
class TaskPool {
    
    private var pool: [Task<Void, Never>] = []

    /// Adds a task to the pool and prepares to automatically remove the task once it's finished.
    func add(_ task: Task<Void, Never>) {
        self.pool.append(task)

        Task {
            _ = await task.result
            self.pool.remove(object: task)
        }
    }

    /// Cancels all tasks currently in the pool and removes them.
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
        taskPool.add(self)
    }
}
