//
//  MomentCaptureCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 7/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator

class MomentCaptureCoordinator: PresentableCoordinator<Moment?> {

    private lazy var momentCaptureVC = MomentCaptureViewController()

    override func toPresentable() -> DismissableVC {
        return self.momentCaptureVC
    }
    
    override func start() {
        super.start()
        
//        self.expressionVC.didCompleteExpression = { [unowned self] expression in
//            self.finishFlow(with: expression)
//        }
    }
}
