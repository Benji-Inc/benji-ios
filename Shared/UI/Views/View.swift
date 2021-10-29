//
//  View.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class View: UIView {

    private var _taskPool: TaskPool? = nil
    /// A collection of tasks that this view might run. Tasks added to the pool will automatically be cancelled if this view is removed from a window.
    var taskPool: TaskPool {
        if let taskPool = self._taskPool {
            return taskPool
        }

        let taskPool = TaskPool()
        self._taskPool = taskPool
        return taskPool
    }

    init() {
        super.init(frame: .zero)
        self.initializeSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.initializeSubviews()
    }
    
    func initializeSubviews() { }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        // Once a view leaves the screen, automatically cancel all of its tasks and reset the task pool.
        if self.window.isNil, _taskPool.exists {
            Task { [weak self] in
                await self?.taskPool.cancelAndRemoveAll()
                self?._taskPool = nil
            }
        }
    }
}
