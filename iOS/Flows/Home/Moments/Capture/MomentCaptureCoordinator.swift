//
//  MomentCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
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

         self.momentCaptureVC.didCompleteMoment = { [unowned self] in
             self.finishFlow(with: nil)
         }
     }
 }
