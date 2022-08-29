//
//  MomentCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator
import StreamChat

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
         
         // If the user has not been added to the comments convo, add them. This will represent views. 
         let controller = ConversationController.controller(for: self.moment.commentsId)
         controller.addMembers(userIds: Set([User.current()!.objectId!]))
         
         self.momentVC.didSelectViewProfile = { [unowned self] person in
             self.presentProfile(for: person)
         }
         
         self.momentVC.reactionsView.reactionsView.didSelect { [unowned self] in
             guard let controller = self.momentVC.reactionsView.controller else { return }
             if let expressions = controller.conversation?.expressions, expressions.count > 0 {
                 self.presentReactions()
             }
         }
         
         self.momentVC.reactionsView.button.didSelect { [unowned self] in
             self.presentAddExpression()
         }
         
         self.momentVC.blurView.button.didSelect { [unowned self] in
             self.presentMomentCapture()
         }
         
         self.momentVC.commentsLabel.didSelect { [unowned self] in
             self.presentComments()
         }
     }
     
     func presentMomentCapture() {         
         let coordinator = MomentCaptureCoordinator(router: self.router, deepLink: self.deepLink)
         
         self.present(coordinator) { [unowned self] result in
             self.momentVC.state = .loading
         }
     }
     
     func presentProfile(for person: PersonType) {
                  
         let coordinator = ProfileCoordinator(with: person, router: self.router, deepLink: self.deepLink)
         
         self.present(coordinator) { [unowned self] result in
             self.finishFlow(with: result)
         }
    }
     
     func presentComments() {
         let coordinator = CommentsCoordinator(router: self.router,
                                               deepLink: self.deepLink,
                                               conversationId: self.moment.commentsId,
                                               startingMessageId: nil,
                                               openReplies: false)
         self.present(coordinator)
     }
     
     func presentReactions() {
         let coordinator = ReactionsDetailCoordinator(router: self.router,
                                                      deepLink: self.deepLink,
                                                      moment: self.moment)
         self.present(coordinator)
     }
     
     func presentAddExpression() {
         let coordinator = ExpressionCoordinator(router: self.router,
                                                 deepLink: self.deepLink)
         
         self.present(coordinator) { [unowned self] result in
             guard let expression = result else { return }
             
             expression.emotions.forEach { emotion in
                 AnalyticsManager.shared.trackEvent(type: .emotionSelected,
                                                    properties: ["value": emotion.rawValue])
             }
             
             let controller = ConversationController.controller(for: self.moment.commentsId)
             
             Task {
                 try await controller.add(expression: expression)
             }
         }
     }
     
     func present<ChildResult>(_ coordinator: PresentableCoordinator<ChildResult>,
                               finishedHandler: ((ChildResult) -> Void)? = nil,
                               cancelHandler: (() -> Void)? = nil) {
         self.removeChild()

         coordinator.toPresentable().dismissHandlers.append { [unowned self] in
             self.momentVC.reactionsView.reactionsView.expressionVideoView.shouldPlay = true
             self.momentVC.expressionView.shouldPlay = true
             self.momentVC.momentView.shouldPlay = true
         }
         
         self.addChildAndStart(coordinator) { [unowned self] result in
             self.momentVC.dismiss(animated: true) {
                 finishedHandler?(result)
             }
         }
         
         self.momentVC.reactionsView.reactionsView.expressionVideoView.shouldPlay = false
         self.momentVC.expressionView.shouldPlay = false
         self.momentVC.momentView.shouldPlay = false
         
         self.router.present(coordinator, source: self.momentVC, cancelHandler: cancelHandler)
     }
 }
