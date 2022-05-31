//
//  TransitionRouter.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit
import Transitions

class TransitionRouter: TransitionableRouter {

    override func handleCustom(type: String,
                               model: Any?,
                               presented presentedTransition: TransitionType,
                               presenting presentingTransition: TransitionType,
                               context: UIViewControllerContextTransitioning) {
        
        logDebug("subclass called for type: \(type)")
        if type == "message" {
#if IOS
            guard let presentedView = model as? MessageContentView else { return }
            switch presentingTransition {
            case .custom(_, let other, _):
                guard let presentingView = other as? MessageContentView else { return }
                if self.isPresenting {
                    self.messageTranstion(fromView: presentingView,
                                          toView: presentedView,
                                          transitionContext: context)
                } else {
                    self.messageTranstion(fromView: presentedView,
                                          toView: presentingView,
                                          transitionContext: context)
                }
            default:
                self.crossDissolveTransition(transitionContext: context)
            }
            #endif
        } else if type == "blur" {
            self.blur(transitionContext: context)
        } else {
            super.handleCustom(type: type, model: model, presented: presentedTransition, presenting: presentingTransition, context: context)
        }
    }
}
