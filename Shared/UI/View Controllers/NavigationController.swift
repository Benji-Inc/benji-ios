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
import Coordinator

class NavigationController: CoordinatorNavigationViewController {

    var cancellables = Set<AnyCancellable>()

    override func initializeViews() {
        super.initializeViews()
        
        self.view.translatesAutoresizingMaskIntoConstraints = true
    }
}
