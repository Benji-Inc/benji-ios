//
//  TransitionRouter.swift
//  Ours
//
//  Created by Benji Dodgson on 1/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
// A custom transitions that simultaneously slides the current VC vertically off the screen
// and the destination one onto it.

class TransitionRouter: NSObject, UIViewControllerAnimatedTransitioning {

    // The fromVC sets the stage for how it wants to get to the toVC
    private(set) var fromVC: TransitionableViewController
    private(set) var toVC: TransitionableViewController
    private let operation: UINavigationController.Operation

    init(fromVC: TransitionableViewController,
         toVC: TransitionableViewController,
         operation: UINavigationController.Operation) {

        self.fromVC = fromVC
        self.toVC = toVC
        self.operation = operation

        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.fromVC.sendingPresentationType.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        let fromTransition = self.fromVC.getTransitionType(for: self.operation, isFromVC: true)
        let toTransition = self.toVC.getTransitionType(for: self.operation, isFromVC: false)

        switch (fromTransition, toTransition) {
        case (let .move(fromView), let .move(toView)):
            self.moveTranstion(fromView: fromView, toView: toView, transitionContext: transitionContext)
        case (let .fill(expandingView), .fade):
            self.fillTranstion(expandingView: expandingView, transitionContext: transitionContext)
        case (.fade, .home):
            #if !APPCLIP && !NOTIFICATION
            self.homeTranstion(fromColor: self.fromVC.transitionColor, transitionContext: transitionContext)
            #else
            self.fadeTranstion(fromColor: self.fromVC.transitionColor, toColor: self.toVC.transitionColor, transitionContext: transitionContext)
            #endif
        default:
            self.fadeTranstion(fromColor: self.fromVC.transitionColor, toColor: self.toVC.transitionColor, transitionContext: transitionContext)
        }
    }
}
