//
//  MomentCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator

 class MomentCoordinator: PresentableCoordinator<ProfileResult?> {

     private let moment: Moment

     private lazy var momentVC: MomentViewController = {
         return MomentViewController(with: self.moment)
     }()

     init(moment: Moment,
          router: CoordinatorRouter,
          deepLink: DeepLinkable?) {

         self.moment = moment

         super.init(router: router, deepLink: deepLink)
     }

     override func toPresentable() -> DismissableVC {
         return self.momentVC
     }
     
     override func start() {
         super.start()
         
         self.momentVC.blurView.button.didSelect { [unowned self] in
             self.presentMomentCapture()
         }
         
         self.momentVC.personView.didSelect { [unowned self] in
             guard let author = self.moment.author else { return }
             self.presentProfile(for: author)
         }
     }
     
     func presentMomentCapture() {
         self.removeChild()
         
         let coordinator = MomentCaptureCoordinator(router: self.router, deepLink: self.deepLink)
         self.addChildAndStart(coordinator) { [unowned self] result in
             self.momentVC.dismiss(animated: true) {
                 self.momentVC.state = .loading
             }
         }
         self.router.present(coordinator, source: self.momentVC, cancelHandler: nil)
     }
     
     func presentProfile(for person: PersonType) {
         
         self.removeChild()
         
         let coordinator = ProfileCoordinator(with: person, router: self.router, deepLink: self.deepLink)
         
         self.addChildAndStart(coordinator) { [unowned self] result in
             self.finishFlow(with: result)
         }
         
         self.router.present(coordinator, source: self.momentVC, cancelHandler: nil)
     }
 }
