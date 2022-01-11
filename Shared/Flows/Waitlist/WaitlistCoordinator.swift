//
//  WaitlistCoordinator.swift
//  Jibber
//
//  Created by Martin Young on 1/10/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WaitlistCoordinator: PresentableCoordinator<Void> {

    private lazy var waitlistVC = WaitlistViewController()

    override func toPresentable() -> DismissableVC {
        return self.waitlistVC
    }
}
