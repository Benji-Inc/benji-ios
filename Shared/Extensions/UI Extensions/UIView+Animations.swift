//
//  UIView+ScalingAnimation.swift
//  Benji
//
//  Created by Benji Dodgson on 12/15/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

extension UIView {

    func scaleDown(xScale: CGFloat = 0.95, yScale: CGFloat = 0.9, hideSubviews: Bool = true) {

        let propertyAnimator = UIViewPropertyAnimator(duration: 0.6,
                                                      dampingRatio: 0.6) {
                                                        self.transform = CGAffineTransform(scaleX: xScale, y: yScale)

            self.subviews.forEach { view in
                view.layoutNow()
            }
        }
        propertyAnimator.startAnimation()
    }

    func scaleUp() {
        let propertyAnimator = UIViewPropertyAnimator(duration: 0.6,
                                                      dampingRatio: 0.6) {
                                                        self.transform = .identity
            self.subviews.forEach { view in
                view.alpha = 1.0
            }
        }
        propertyAnimator.startAnimation()
    }

    @MainActor
    static func awaitAnimation(with duration: Theme.AnimationDuration,
                               delay: TimeInterval = 0.0,
                               options: AnimationOptions = .curveLinear,
                               animations: @MainActor @escaping () -> Void) async {
        return await withCheckedContinuation { continuation in
            UIView.animate(withDuration: duration.rawValue,
                           delay: delay,
                           options: options) {
                animations()
            } completion: { _ in
                continuation.resume(with: .success(()))
            }
        }
    }

    @MainActor
    static func awaitSpringAnimation(with duration: Theme.AnimationDuration,
                                     delay: TimeInterval = 0.0,
                                     damping: CGFloat = 0.65,
                                     velocity: CGFloat = 1.0,
                                     options: AnimationOptions = .curveEaseInOut,
                                     animations: @MainActor @escaping () -> Void) async {
        
        return await withCheckedContinuation { continuation in
            UIView.animate(withDuration: duration.rawValue,
                           delay: delay,
                           usingSpringWithDamping: damping,
                           initialSpringVelocity: velocity,
                           options: options,
                           animations:
                            {
                animations()
            }) { _ in
                continuation.resume(with: .success(()))
            }
        }
    }
}
