//
//  ViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import UIKit
import Combine

class ViewController: UIViewController, Dismissable {

    var dismissHandlers: [DismissHandler] = []
    var cancellables = Set<AnyCancellable>()
    /// A pool of Tasks that are automatically cancelled when our view disappears
    var autocancelTaskPool = TaskPool()
    
    var analyticsIdentifier: String? {
        return nil
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        self.initializeViews()
    }

    deinit {
        self.cancellables.forEach { (cancellable) in
            cancellable.cancel()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeViews()
    }

    func initializeViews() { }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if self.isBeingOpen {
            self.viewWasPresented()
        }
        
        self.trackScreenDidAppearEvent()
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

        // If our view goes off the screen, automatically cancel any tasks associated with it.
        self.autocancelTaskPool.cancelAndRemoveAll()
    }

    /// Called right after this VC's view is removed from the view hierarchy due to a dismiss/pop call or removed as a child view controller.
    /// This will only be called once in the VC's lifecycle unless it presented and dismissed again.
    func viewWasDismissed() { }
    
    func trackScreenDidAppearEvent() {
        if let identifier = self.analyticsIdentifier {
            AnalyticsManager.shared.trackStreen(type: identifier, properties: nil)
        }
    }
}

