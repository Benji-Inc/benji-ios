//
//  MomentCaptureCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 7/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator

class MomentCoordinator: PresentableCoordinator<Moment?> {

    private lazy var momentCaptureVC = MomentViewController()

    override func toPresentable() -> DismissableVC {
        return self.momentCaptureVC
    }
    
    override func start() {
        super.start()
        
        self.momentCaptureVC.didCompleteMoment = { [unowned self] moment in 
            self.finishFlow(with: moment)
        }
    }
}
