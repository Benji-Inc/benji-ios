//
//  SwitchableContentViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 1/14/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import UIKit

class SwitchableContentViewController<ContentType: Switchable>: UserOnboardingViewController {

    private(set) var currentContent: ContentType?
    private var currentCenterVC: (UIViewController & Sizeable)?

    private var prepareAnimator: UIViewPropertyAnimator?
    private var presentAnimator: UIViewPropertyAnimator?

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.currentCenterVC?.view.expandToSuperviewSize()
    }

    func switchTo(_ content: ContentType) {
        // Don't interrupt currently running animations.
        if let animator = self.prepareAnimator, animator.isRunning { return }
        if let animator = self.presentAnimator, animator.isRunning { return }

        self.currentContent = content

        self.prepareAnimator = UIViewPropertyAnimator.init(duration: Theme.animationDurationStandard,
                                                           curve: .easeOut,
                                                           animations: {
            self.prepareForPresentation()
        })

        self.prepareAnimator?.addCompletion({ (position) in
            if position == .end {
                self.currentCenterVC?.removeFromParentAndSuperviewIfNeeded()

                self.updateUI()

                self.currentCenterVC = content.viewController

                if let contentVC = self.currentCenterVC {
                    self.addChild(contentVC)
                    self.view.insertSubview(contentVC.view, belowSubview: self.nameLabel)
                }

                self.willUpdateContent()

                self.view.layoutNow()

                self.animatePresentation()
            }
        })

        self.prepareAnimator?.startAnimation()
    }

    private func prepareForPresentation() {
        self.messageBubble.alpha = 0
        self.textView.alpha = 0
        self.currentCenterVC?.view.alpha = 0
    }

    private func animatePresentation() {
        self.presentAnimator = UIViewPropertyAnimator.init(duration: Theme.animationDurationStandard,
                                                           curve: .easeOut,
                                                           animations: {

            self.messageBubble.alpha = 1
            self.textView.alpha = 1
            self.currentCenterVC?.view.alpha = 1
        })
        
        self.presentAnimator?.startAnimation()
    }

    /// Called whenever a new content vc is about to be presented.
    func willUpdateContent() {}
}
