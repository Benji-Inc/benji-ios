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
        
        switch type {
        #if iOS
        case "message":
            guard let presentedView = model as? MessageContentView else { return }
            switch presentingTransition {
            case .custom(let type, let other, _):
                guard let presentingView = other as? MessageContentView else { return }
                if self.isPresenting {
                    self.messageTranstion(fromView: presentingView,
                                          toView: presentedView,
                                          transitionContext: transitionContext)
                } else {
                    self.messageTranstion(fromView: presentedView,
                                          toView: presentingView,
                                          transitionContext: transitionContext)
                }
            default:
                self.crossDissolveTransition(transitionContext: context)
            }
        #endif
        case "blur":
            self.blur(transitionContext: context)
        default:
            break 
        }
    }
}
