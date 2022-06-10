//
//  BaseView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit
import Combine

class BaseView: UIView {

    /// A collection of tasks that this view might run. Tasks added to the pool will automatically be cancelled if this view is removed from a window.
    var taskPool = TaskPool()
    
    var cancellables = Set<AnyCancellable>()

    init() {
        super.init(frame: .zero)
        self.initializeSubviews()
    }
    
    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Don't call initialize subviews here because it can cause a crash.
        // Instead call from from awake from nib.
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.initializeSubviews()
    }
    
    func initializeSubviews() { }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        // Once a view leaves the screen, automatically cancel all of its tasks and reset the task pool.
        if self.window.isNil {
            self.taskPool.cancelAndRemoveAll()
        }
    }
}
