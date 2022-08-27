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
         
         self.momentVC.expressionsButton.didSelect { [unowned self] in
             self.presentAddExpression()
         }
         
         self.momentVC.blurView.button.didSelect { [unowned self] in
             self.presentMomentCapture()
         }
         
         self.momentVC.personView.didSelect { [unowned self] in
             guard let author = self.moment.author else { return }
             self.presentProfile(for: author)
         }
         
         self.momentVC.commentsLabel.didSelect { [unowned self] in
             self.presentComments()
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
     
     func presentComments() {
         self.removeChild()
         
         let coordinator = CommentsCoordinator(router: self.router,
                                               deepLink: self.deepLink,
                                               conversationId: self.moment.commentsId,
                                               startingMessageId: nil,
                                               openReplies: false)
         self.addChildAndStart(coordinator, finishedHandler: { [unowned self] (_) in
             self.momentVC.dismiss(animated: true)
         })
         
         self.router.present(coordinator, source: self.momentVC)
     }
     
     func presentExpressions(startingExpression: ExpressionInfo, expressions: [ExpressionInfo]) {
         
         let controller = ConversationController.controller(for: self.moment.commentsId)

         let coordinator = ExpressionDetailCoordinator(router: self.router,
                                                       deepLink: self.deepLink,
                                                       startingExpression: startingExpression,
                                                       expressions: expressions)
         self.addChildAndStart(coordinator) { [unowned self] result in
             
         }
         
         self.router.present(coordinator, source: self.momentVC, cancelHandler: nil)
     }
     
     func presentAddExpression() {
         let coordinator = ExpressionCoordinator(favoriteType: nil,
                                                 router: self.router,
                                                 deepLink: self.deepLink)
         self.addChildAndStart(coordinator) { [unowned self] result in
             guard let expression = result else { return }
             
             expression.emotions.forEach { emotion in
                 AnalyticsManager.shared.trackEvent(type: .emotionSelected,
                                                    properties: ["value": emotion.rawValue])
             }
             
             let controller = ConversationController.controller(for: self.moment.commentsId)
             
             Task {
                 try await controller.add(expression: expression)
             }
             self.momentVC.dismiss(animated: true)
         }
         self.router.present(coordinator, source: self.momentVC, cancelHandler: nil)
     }
 }
