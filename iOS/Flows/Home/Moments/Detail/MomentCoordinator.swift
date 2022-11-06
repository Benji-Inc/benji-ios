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

 class MomentCoordinator: PresentableCoordinator<ProfileResult?>, DeepLinkHandler {

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
         
         self.momentVC.contentView.delegate = self
         
         self.momentVC.footerView.reactionsView.reactionsView.didSelect { [unowned self] in
             guard let controller = self.momentVC.footerView.reactionsView.controller else { return }
             if let expressions = controller.conversation?.expressions, expressions.count > 0 {
                 if self.moment.isAvailable {
                     self.presentReactions()
                 } else {
                     self.showReactionsAlert()
                 }
             }
         }
         
         self.momentVC.footerView.reactionsView.button.didSelect { [unowned self] in
             if self.moment.isAvailable {
                 self.presentAddExpression()
             } else {
                 self.showReactionsAlert()
             }
         }
         
         self.momentVC.footerView.commentsLabel.didSelect { [unowned self] in
             if self.moment.isAvailable {
                 self.presentComments()
             } else {
                 self.showCommentsAlert()
             }
         }
         
         self.momentVC.footerView.shareButton.didSelect { [unowned self] in
             self.presentShareSheet()
         }
         
         if let deepLink = self.deepLink {
             self.handle(deepLink: deepLink)
         }
     }
     
     func handle(deepLink: DeepLinkable) {
         guard let target = deepLink.deepLinkTarget else {
             return
         }

         switch target {
         case .comment:
             Task.onMainActorAsync {
                 await Task.sleep(seconds: 0.25)
                 self.presentComments()
             }
         case .capture:
             self.presentMomentCapture()
         default:
             break
         }
     }
     
     func presentMomentCapture() {         
         let coordinator = MomentCaptureCoordinator(router: self.router, deepLink: self.deepLink)
         
         self.present(coordinator) { [unowned self] result in
             self.momentVC.showMomentIfAvailable()
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
             self.momentVC.footerView.reactionsView.reactionsView.expressionVideoView.shouldPlay = true
             self.momentVC.contentView.play()
         }
         
         self.addChildAndStart(coordinator) { [unowned self] result in
             self.momentVC.dismiss(animated: true) {
                 finishedHandler?(result)
             }
         }
         
         self.momentVC.footerView.reactionsView.reactionsView.expressionVideoView.shouldPlay = false
         self.momentVC.contentView.pause()
         
         self.router.present(coordinator, source: self.momentVC, cancelHandler: cancelHandler)
     }
     
     func showCommentsAlert() {
         let alert = UIAlertController(title: "Comments Unavailable",
                                       message: "To view comments, record today's moment.",
                                       preferredStyle: .alert)
         
         let record = UIAlertAction(title: "Record", style: .default) { [unowned self] _ in
             self.presentMomentCapture()
         }
         
         let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
         
         alert.addAction(record)
         alert.addAction(cancel)
         
         self.router.topmostViewController.present(alert, animated: true)
     }
     
     func showReactionsAlert() {
         let alert = UIAlertController(title: "Reactions Unavailable",
                                       message: "To view reactions, record today's moment.",
                                       preferredStyle: .alert)
         
         let record = UIAlertAction(title: "Record", style: .default) { [unowned self] _ in
             self.presentMomentCapture()
         }
         
         let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
         
         alert.addAction(record)
         alert.addAction(cancel)
         
         self.router.topmostViewController.present(alert, animated: true)
     }
     
     func presentShareSheet() {
         Task {
             await self.moment.prepareMetadata()
             
             let activityVC = ActivityViewController(with: self, activityItems: [self.moment])
             self.router.topmostViewController.present(activityVC, animated: true)
         }
     }
 }

extension MomentCoordinator: MomentContentViewDelegate {
    func momentContentViewDidSelectCapture(_ view: MomentContentView) {
        self.presentMomentCapture()
    }
    
    func momentContent(_ view: MomentContentView, didSelectPerson person: PersonType) {
        self.presentProfile(for: person)
    }
}

extension MomentCoordinator: ActivityViewControllerDelegate {
    
    func activityView(_ controller: ActivityViewController, didCompleteWith result: ActivityViewController.Result) {
        
    }
}
