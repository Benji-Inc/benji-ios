//
//  ToastView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import UIKit

enum ToastState {
    case hidden, present, left, expanded, alphaIn, dismiss, gone
}

protocol ToastViewable {
    var toast: Toast { get set }
    var didPrepareForPresentation: () -> Void { get set }
    var didDismiss: () -> Void { get set }
    var didTap: () -> Void { get set }
    func reveal()
    func dismiss()
    init(with toast: Toast)
}

class ToastView: BaseView, ToastViewable {

    var toast: Toast
    var didPrepareForPresentation: () -> Void = {}
    var didDismiss: () -> Void = {}
    var didTap: () -> Void = {}

    var panStart: CGPoint?
    var startY: CGFloat?

    var maxHeight: CGFloat?
    var screenOffset: CGFloat = 50

    var cancellables = Set<AnyCancellable>()

    var state: ToastState = .hidden {
        didSet {
            if self.state != oldValue {
                self.update(for: self.state)
            }
        }
    }

    let revealAnimator = UIViewPropertyAnimator(duration: 0.35,
                                                dampingRatio: 0.6,
                                                animations: nil)

    let dismissAnimator = UIViewPropertyAnimator(duration: 0.35,
                                                 dampingRatio: 0.6,
                                                 animations: nil)

    required init(with toast: Toast) {
        self.toast = toast
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.isUserInteractionEnabled = true
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Theme.cornerRadius

        self.didSelect { [unowned self] in
            self.toast.didTap()
            self.dismiss()
        }

        self.isHidden = true
        
        Task {
            await Task.snooze(seconds: 0.1)
            self.update(for: self.state)
            self.didPrepareForPresentation()
        }.add(to: self.taskPool)

        #if !NOTIFICATION
        guard let superview = UIWindow.topWindow() else { return }
        superview.addSubview(self)
        #endif

        self.addPan()
    }

    func reveal() {
        self.revealAnimator.stopAnimation(true)
        self.revealAnimator.addAnimations { [unowned self] in
            self.state = .present
        }

        self.revealAnimator.addCompletion({ [unowned self] (position) in
            if position == .end {
                self.didReveal()
            }
        })
        self.revealAnimator.startAnimation(afterDelay: 0.5)
    }

    func didReveal() {
        Task {
            await Task.sleep(seconds: self.toast.duration)
            if self.state != .gone {
                self.dismiss()
            } else {
                self.taskPool.cancelAndRemoveAll()
            }

        }.add(to: self.taskPool)
    }

    func dismiss() {
        self.revealAnimator.stopAnimation(true)

        self.dismissAnimator.addAnimations{ [unowned self] in
            self.state = .dismiss
        }

        self.dismissAnimator.addCompletion({ [unowned self] (position) in
            if position == .end {
                self.state = .gone
                self.didDismiss()
            }
        })
        self.dismissAnimator.startAnimation()
    }

    func update(for state: ToastState) {
        #if !NOTIFICATION
        guard let superView = UIWindow.topWindow() else { return }

        switch state {
        case .hidden:
            if self.toast.position == .top {
                self.bottom = superView.top - self.screenOffset - superView.safeAreaInsets.top
            } else {
                self.top = superView.bottom + self.screenOffset + superView.safeAreaInsets.bottom
            }
        case .present:
            self.isHidden = false 
            if self.toast.position == .top {
                self.top = superView.top + self.screenOffset
            } else {
                self.bottom = superView.bottom - self.screenOffset
            }
        case .left:
            break
        case .expanded:
            break
        case .alphaIn:
            break
        case .dismiss, .gone:
            if self.toast.position == .top {
                self.bottom = superView.top + 10
            } else {
                self.top = superView.bottom - 10
            }
        }
        #endif

        self.layoutNow()
    }

    private func addPan() {
        let panRecognizer = PanGestureRecognizer { [unowned self] panRecognizer in
            self.handle(panRecognizer: panRecognizer)
        }
        self.addGestureRecognizer(panRecognizer)
    }

    private func handle(panRecognizer: UIPanGestureRecognizer) {
        #if !NOTIFICATION
        guard let superview = UIWindow.topWindow() else { return }

        switch panRecognizer.state {
        case .began:
            self.initializePanIfNeeded(panRecognizer: panRecognizer)
        case .changed:
            self.initializePanIfNeeded(panRecognizer: panRecognizer)

            if let panStart = self.panStart, let startY = self.startY {
                let delta = panStart.y + panRecognizer.translation(in: superview).y
                self.centerY = (startY...CGFloat.greatestFiniteMagnitude).clamp(delta + startY)
            }
        case .ended, .cancelled, .failed:
            // Ensure we don't respond the end of an untracked pan gesture
            let offset = superview.height - self.screenOffset * 0.5
            if self.top <= offset {
                self.dismiss()
            }
        case .possible:
            break
        @unknown default:
            break
        }
        #endif
    }

    private func initializePanIfNeeded(panRecognizer: UIPanGestureRecognizer) {
        #if !NOTIFICATION
        if self.panStart == nil, let superview = UIWindow.topWindow() {
            self.startY = self.centerY
            self.panStart = panRecognizer.translation(in: superview)
        }
        #endif
    }
}
