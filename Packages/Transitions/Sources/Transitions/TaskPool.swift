//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/30/22.
//

import Foundation

/// A collection of tasks that automatically handles removing tasks from itself when the tasks finish.
public class TaskPool {
    
    private var pool: [Task<Void, Never>] = []

    /// Adds a task to the pool and prepares to automatically remove the task once it's finished.
    public func add(_ task: Task<Void, Never>) {
        self.pool.append(task)

        Task { [weak self] in
            _ = await task.result
            self?.pool.remove(object: task)
        }
    }

    /// Cancels all tasks currently in the pool and removes them.
    public func cancelAndRemoveAll() {
        for task in self.pool {
            task.cancel()
        }
        self.pool.removeAll()
    }
}

public extension Task where Success == Void, Failure == Never {

    /// Adds the task to the given task pool. Once the task is finished, the task is removed from the pool.
    @discardableResult
    func add(to taskPool: TaskPool) -> Task<Success, Failure> {
        taskPool.add(self)
        return self
    }
}

extension Array where Element: Equatable {

    // Remove first collection element that is equal to the given object
    mutating func remove(object: Element) {
        if let index = self.firstIndex(of: object) {
            self.remove(at: index)
        }
    }
}
