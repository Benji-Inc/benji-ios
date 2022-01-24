//
//  NavigationController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit
import Combine

class NavigationController: UINavigationController, Dismissable {

    var dismissHandlers: [DismissHandler] = []
    var cancellables = Set<AnyCancellable>()

    init() {
        super.init(nibName: nil, bundle: nil)
        self.initializeViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeViews()
    }

    func initializeViews() {
        self.view.translatesAutoresizingMaskIntoConstraints = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if self.isBeingOpen {
            self.viewWasPresented()
        }
    }

    /// Called right after this VC's view is added to the view hierarchy from a presentation or a being added as a child view controller.
    /// This will only be called once in the VC's lifecycle unless it is dismissed and presented again.
    func viewWasPresented() {}

    override func viewDidDisappear(_ animated: Bool) {
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
    func viewWasDismissed() { }
}
