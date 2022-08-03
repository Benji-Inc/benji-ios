//
//  MomentDetailCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator

 class MomentDetailCoordinator: PresentableCoordinator<Void> {

     private let moment: Moment

     private lazy var momentDetailVC: MomentDetailViewController = {
         return MomentDetailViewController(with: self.moment)
     }()

     init(moment: Moment,
          router: CoordinatorRouter,
          deepLink: DeepLinkable?) {

         self.moment = moment

         super.init(router: router, deepLink: deepLink)
     }

     override func toPresentable() -> DismissableVC {
         return self.momentDetailVC
     }
 }
