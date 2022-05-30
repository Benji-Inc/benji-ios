//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/26/22.
//

import Foundation
import UIKit

open class CoordinatorNavigationViewController: UINavigationController, Dismissable {

    public var dismissHandlers: [DismissHandler] = []

    public init() {
        super.init(nibName: nil, bundle: nil)
        self.initializeViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeViews()
    }

    open func initializeViews() {}

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if self.isBeingOpen {
            self.viewWasPresented()
        }
    }

    /// Called right after this VC's view is added to the view hierarchy from a presentation or a being added as a child view controller.
    /// This will only be called once in the VC's lifecycle unless it is dismissed and presented again.
    open func viewWasPresented() {}

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if self.isBeingClosed {
            self.viewWasDismissed()
            self.dismissHandlers.forEach { (dismissHandler) in
                dismissHandler.handler?()
            }
        }
    }

    /// Called right after this VC's view is removed from the view hierarchy due to a dismiss/pop call or removed as a child view controller.
    /// This will only be called once in the VC's lifecycle unless it presented and dismissed again.
    open func viewWasDismissed() { }
}
