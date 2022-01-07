//
//  TransitionRouter+Fill.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

extension TransitionRouter {

    func fillTranstion(expandingView: UIView, transitionContext: UIViewControllerContextTransitioning) {

        let containerView = transitionContext.containerView

        if let presentedView = transitionContext.view(forKey: UITransitionContextViewKey.to) {

            let startingPoint: CGPoint = expandingView.convert(expandingView.bounds, to: containerView).center

            let viewCenter = presentedView.center
            let viewSize = presentedView.size

            let circle = BaseView()
            circle.frame = self.frameForCircle(withViewCenter: viewCenter, size: viewSize, startPoint: startingPoint)

            circle.layer.cornerRadius = circle.halfHeight
            circle.center = startingPoint
            circle.set(backgroundColor: .B1)
            circle.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            containerView.addSubview(circle)

            presentedView.center = startingPoint
            presentedView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            presentedView.alpha = 0
            presentedView.subviews.forEach { (subview) in
                subview.alpha = 0
            }
            containerView.addSubview(presentedView)

            let duration = self.transitionDuration(using: transitionContext) * 0.5
            UIView.animate(withDuration: duration,
                           delay: 0.33,
                           options: .curveEaseIn,
                           animations: {
                            circle.transform = .identity
                            presentedView.transform = .identity
                            presentedView.alpha = 1
                            presentedView.center = viewCenter
            }) { (_) in }

            UIView.animate(withDuration: duration,
                           delay: 0.33 + duration,
                           options: .curveEaseInOut,
                           animations: {
                            presentedView.subviews.forEach { (subview) in
                                subview.alpha = 1
                            }
            }) { (_) in
                // Unhide all of the views we tampered with so that they're visible after the transition
                circle.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }

    func frameForCircle(withViewCenter viewCenter: CGPoint,
                        size viewSize: CGSize,
                        startPoint: CGPoint) -> CGRect {

        let xLength = fmax(startPoint.x, viewSize.width - startPoint.x)
        let yLength = fmax(startPoint.y, viewSize.height - startPoint.y)

        let offestVector = sqrt(xLength * xLength + yLength * yLength) * 2
        let size = CGSize(width: offestVector, height: offestVector)

        return CGRect(origin: .zero, size: size)
    }
}

