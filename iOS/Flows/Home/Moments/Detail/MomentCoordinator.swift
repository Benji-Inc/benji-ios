//
//  MomentCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator
import UIKit

enum ProfileResult {
    case conversation(String)
    #if IOS
    case openReplies(Messageable)
    case message(Messageable)
    #endif
}

class MomentCoordinator: PresentableCoordinator<ProfileResult?>, DeepLinkHandler {
    
    let moment: Moment
    
    lazy var momentVC: MomentViewController = {
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
        
        #if IOS
        self.momentVC.contentView.delegate = self
        #endif
        
        self.momentVC.footerView.reactionsView.reactionsView.didSelect { [unowned self] in
            #if IOS
            guard let controller = self.momentVC.footerView.reactionsView.controller else { return }
            if let expressions = controller.conversation?.expressions, expressions.count > 0 {
                if self.moment.isAvailable {
                    self.presentReactions()
                } else {
                    self.showReactionsAlert()
                }
            }
            #elseif APPCLIP
            self.presentOnboardingAlert()
            #endif
        }
        
        self.momentVC.footerView.reactionsView.button.didSelect { [unowned self] in
            #if IOS
            if self.moment.isAvailable {
                self.presentAddExpression()
            } else {
                self.showReactionsAlert()
            }
            #elseif APPCLIP
            self.presentOnboardingAlert()
            #endif
        }
        
        self.momentVC.footerView.commentsLabel.didSelect { [unowned self] in
            #if IOS
            if self.moment.isAvailable {
                self.presentComments()
            } else {
                self.showCommentsAlert()
            }
            #elseif APPCLIP
            self.presentOnboardingAlert()
            #endif
        }
        
        self.momentVC.footerView.shareButton.didSelect { [unowned self] in
            #if IOS
            self.presentShareSheet()
            #elseif APPCLIP
            self.presentOnboardingAlert()
            #endif
        }
        
        if let deepLink = self.deepLink {
            self.handle(deepLink: deepLink)
        }
    }
    
    func handle(deepLink: DeepLinkable) {
        guard let target = deepLink.deepLinkTarget else {
            return
        }
        
        #if IOS
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
        #endif
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
    
    #if APPCLIP
    func presentOnboardingAlert() {
        let alert = UIAlertController(title: "Login Required",
                                      message: "To interact with this Moment, simply login or signup.",
                                      preferredStyle: .alert)
        
        let login = UIAlertAction(title: "Login", style: .default) { [unowned self] _ in
            self.finishFlow(with: nil)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        
        alert.addAction(login)
        alert.addAction(cancel)
        
        self.router.topmostViewController.present(alert, animated: true)
    }
    #endif
}
