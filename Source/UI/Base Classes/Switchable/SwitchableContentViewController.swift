//
//  SwitchableContentViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 1/14/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Combine

class SwitchableContentViewController<ContentType: Switchable>: NavigationBarViewController, KeyboardObservable {

    @Published var current: ContentType?

    private var currentCenterVC: (UIViewController & Sizeable)?

    private var prepareAnimator: UIViewPropertyAnimator?
    private var presentAnimator: UIViewPropertyAnimator?

    override func initializeViews() {
        super.initializeViews()

        // Must be called here 
        self.current = self.getInitialContent()

        // Need to call prepare before switchContent so content doesnt flicker on first load
        self.prepareForPresentation()

        self.$current.mainSink { [weak self] (value) in
                guard let `self` = self else { return }
                guard let content = value else { return }
                self.switchTo(content)
            }
            .store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let current = self.current else { return }

        let yOffset = self.lineView.bottom 
        var vcHeight = current.viewController.getHeight(for: self.scrollView.width)
        if vcHeight <= .zero {
            vcHeight = self.scrollView.height - self.lineView.bottom - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom
        }
        let keyboardHeight: CGFloat = self.keyboardHandler?.currentKeyboardHeight ?? 0
        let contentHeight = yOffset + vcHeight + keyboardHeight
        self.scrollView.contentSize = CGSize(width: self.scrollView.width, height: contentHeight)

        current.viewController.view.frame = CGRect(x: 0,
                                                   y: yOffset,
                                                   width: self.scrollView.width,
                                                   height: vcHeight)
    }

    func getInitialContent() -> ContentType {
        fatalError("No initial content type set")
    }

    func switchTo(_ content: ContentType) {

        if let animator = self.prepareAnimator, animator.isRunning {
            return
        }

        if let animator = self.presentAnimator, animator.isRunning {
            return
        }

        self.prepareAnimator = UIViewPropertyAnimator.init(duration: Theme.animationDuration,
                                                           curve: .easeOut,
                                                           animations: {
                                                            self.prepareForPresentation()
                                                           })

        self.prepareAnimator?.addCompletion({ (position) in
            if position == .end {

                self.currentCenterVC?.removeFromParentSuperview()

                self.updateNavigationBar()

                self.currentCenterVC = content.viewController
                let showBackButton = content.shouldShowBackButton

                if let contentVC = self.currentCenterVC {
                    self.addChild(viewController: contentVC, toView: self.scrollView)
                }

                self.willUpdateContent()

                self.view.layoutNow()

                self.animatePresentation(showBackButton: showBackButton)
            }
        })

        self.prepareAnimator?.startAnimation()
    }

    private func prepareForPresentation() {
        self.titleLabel.alpha = 0
        self.titleLabel.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)

        self.descriptionLabel.alpha = 0
        self.descriptionLabel.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)

        self.currentCenterVC?.view.alpha = 0
        self.backButton.alpha = 0
    }

    private func animatePresentation(showBackButton: Bool) {

        self.presentAnimator = UIViewPropertyAnimator.init(duration: Theme.animationDuration,
                                                           curve: .easeOut,
                                                           animations: {

                                                            self.titleLabel.alpha = 1
                                                            self.titleLabel.transform = .identity

                                                            self.descriptionLabel.alpha = 1
                                                            self.descriptionLabel.transform = .identity

                                                            self.currentCenterVC?.view.alpha = 1
                                                            self.backButton.alpha = showBackButton ? 1 : 0
                                                           })
        
        self.presentAnimator?.startAnimation()
    }

    func handleKeyboard(frame: CGRect,
                        with animationDuration: TimeInterval,
                        timingCurve: UIView.AnimationCurve) {

        UIView.animate(withDuration: animationDuration, animations: {
            self.view.layoutNow()
        })
    }

    func willUpdateContent() {}
}
