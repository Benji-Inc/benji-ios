//
//  ViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import UIKit
import Combine
import Coordinator

class ViewController: CoordinatorViewController {

    var cancellables = Set<AnyCancellable>()
    /// A pool of Tasks that are automatically cancelled when our view disappears
    var autocancelTaskPool = TaskPool()
    
    /// Used to identify a screen
    var analyticsIdentifier: String? {
        return nil
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    deinit {
        self.cancellables.forEach { (cancellable) in
            cancellable.cancel()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.trackScreenDidAppearEvent()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // If our view goes off the screen, automatically cancel any tasks associated with it.
        self.autocancelTaskPool.cancelAndRemoveAll()
    }
    
    /// Called in viewDidAppear. Used to track screens becoming visible.
    func trackScreenDidAppearEvent() {
        if let identifier = self.analyticsIdentifier {
            AnalyticsManager.shared.trackStreen(type: identifier, properties: nil)
        }
    }
}

