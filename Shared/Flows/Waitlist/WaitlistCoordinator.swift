//
//  WaitlistCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/12/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WaitlistCoordinator: PresentableCoordinator<Void> {
    
    lazy var waitlistVC = WaitlistViewController()
    
    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.waitlistVC
    }
}
