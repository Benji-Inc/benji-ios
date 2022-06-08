//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/30/22.
//

import Foundation
import UIKit

open class TransitionableRouter: NSObject, UIViewControllerAnimatedTransitioning {
    
    // The fromVC sets the stage for how it wants to get to the toVC
    public var fromVC: TransitionableViewController
    public var toVC: TransitionableViewController
    public let taskPool = TaskPool()
    public let operation: UINavigationController.Operation
    public var isPresenting: Bool {
        return self.operation == .push
    }
        
    public init(fromVC: TransitionableViewController,
                toVC: TransitionableViewController,
                operation: UINavigationController.Operation) {
        
        self.fromVC = fromVC
        self.toVC = toVC
        self.operation = operation
        
        super.init()
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        let isPresenting = self.operation == .push
        if isPresenting {
            return self.getDuration(for: self.toVC.presentationType)
        } else {
            return self.getDuration(for: self.fromVC.dismissalType)
        }
    }
    
    open func getDuration(for type: TransitionType) -> TimeInterval {
        switch type {
        case .custom(_, _, duration: let duration):
            return duration
        default:
            return 0.5
        }
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let isPresenting = self.operation == .push
        
        let presentedVCTransition: TransitionType
        let presentingVCTransition: TransitionType
        if isPresenting {
            presentedVCTransition = self.toVC.presentationType
            presentingVCTransition = self.fromVC.getFromVCPresentationType(for: presentedVCTransition)
        } else {
            presentedVCTransition = self.fromVC.dismissalType
            presentingVCTransition = self.toVC.getToVCDismissalType(for: presentedVCTransition)
        }
        
        switch presentedVCTransition {
        case .move(let presentedView):
            // A move transition required that both VCs support the move style.
            // If one does not, fall back to a cross dissolve animation.
            switch presentingVCTransition {
            case .move(let presentingView):
                if isPresenting {
                    self.moveTranstion(fromView: presentingView,
                                       toView: presentedView,
                                       transitionContext: transitionContext)
                } else {
                    self.moveTranstion(fromView: presentedView,
                                       toView: presentingView,
                                       transitionContext: transitionContext)
                }
            default:
                self.crossDissolveTransition(transitionContext: transitionContext)
            }
        case .fadeOutIn:
            self.fadeTransition(transitionContext: transitionContext)
        case .crossDissolve:
            self.crossDissolveTransition(transitionContext: transitionContext)
        case .fill(let expandingView, let color):
            self.fillTranstion(expandingView: expandingView, fillColor: color, transitionContext: transitionContext)
        case .modal:
            break
        case .custom(type: let value, let model, _):
            self.handleCustom(type: value,
                              model: model,
                              presented: presentedVCTransition,
                              presenting: presentingVCTransition,
                              context: transitionContext)
        }
    }
    
    open func handleCustom(type: String,
                           model: Any?,
                           presented presentedTransition: TransitionType,
                           presenting presentingTransition: TransitionType,
                           context: UIViewControllerContextTransitioning) {
        fatalError("custom transition not implemented for type: \(type)")
    }
    
    open func animationEnded(_ transitionCompleted: Bool) {
        self.taskPool.cancelAndRemoveAll()
    }
}
