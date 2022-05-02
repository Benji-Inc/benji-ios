//
//  TransitionRouter+CrossDissolve.swift
//  Jibber
//
//  Created by Martin Young on 5/2/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

extension TransitionRouter {

    /// Dissolves from fromVC to the toVC and vice versa.
    func crossDissolveTransition(transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        containerView.backgroundColor = .red

        // We only need to add the toVC to the container if we're presenting it.


        let isPresenting = self.operation == .push
        if isPresenting {
            containerView.addSubview(self.toVC.view)
            self.toVC.view.frame = transitionContext.finalFrame(for: self.toVC)
            // Temporarily hide the toVC. We'll gradually fade it in over the top of the from vc.
            self.toVC.navigationController?.navigationBar.alpha = 0
            self.toVC.view.alpha = 0
        } else {
            containerView.insertSubview(self.toVC.view, at: 0)
        }

        UIView.animate(withDuration: 5,// self.transitionDuration(using: transitionContext),
                       delay: 0,
                       options: .curveLinear) {
            if isPresenting {
                self.toVC.view.alpha = 1
                self.toVC.navigationController?.navigationBar.alpha = 1
            } else {
                self.fromVC.view.alpha = 0
                self.fromVC.navigationController?.navigationBar.alpha = 0
            }
        } completion: { (completed) in
            transitionContext.completeTransition(true)
            if isPresenting {

                                self.fromVC.view.removeFromSuperview()
            }
        }
    }
}
