//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/30/22.
//

import Foundation
import UIKit

extension TransitionableRouter {

    func fillTranstion(expandingView: UIView,
                       fillColor: UIColor,
                       transitionContext: UIViewControllerContextTransitioning) {

        let containerView = transitionContext.containerView

        if let presentedView = transitionContext.view(forKey: UITransitionContextViewKey.to) {

            let startingPoint: CGPoint = expandingView.convert(expandingView.bounds, to: containerView).center

            let viewCenter = presentedView.center
            let viewSize = presentedView.size

            let circle = UIView()
            circle.frame = self.frameForCircle(withViewCenter: viewCenter, size: viewSize, startPoint: startingPoint)

            circle.layer.cornerRadius = circle.halfHeight
            circle.center = startingPoint
            circle.backgroundColor = fillColor
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

private extension CGRect {
    
    /// Alias for origin.x.
    var x: CGFloat {
        get {return origin.x}
        set {origin.x = newValue}
    }
    /// Alias for origin.y.
    var y: CGFloat {
        get {return origin.y}
        set {origin.y = newValue}
    }
    
    /// Accesses origin.x + 0.5 * size.width.
    var centerX: CGFloat {
        get {return x + width * 0.5}
        set {x = newValue - width * 0.5}
    }
    
    /// Accesses origin.y + 0.5 * size.height.
    var centerY: CGFloat {
        get {return y + height * 0.5}
        set {y = newValue - height * 0.5}
    }
    
    /// Accesses the point at the center.
    var center: CGPoint {
        get {return CGPoint(x: centerX, y: centerY)}
        set {centerX = newValue.x; centerY = newValue.y}
    }
}

private extension UIView {
    
    var size: CGSize {
        get {
            return CGSize(width: self.width, height: self.height)
        }

        set {
            self.width = newValue.width
            self.height = newValue.height
        }
    }
    
    var width: CGFloat {
        get {
            return self.frame.size.width
        }

        set {
            var frame = self.frame
            frame.size.width = newValue
            self.frame = frame
        }
    }

    var height: CGFloat {
        get {
            return self.frame.size.height
        }

        set {
            var frame = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
    }
    
    var halfHeight: CGFloat {
        get {
            return 0.5*self.frame.size.height
        }
    }
}
