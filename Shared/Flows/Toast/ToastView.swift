//
//  ToastView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

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

class ToastView: View, ToastViewable {

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

        self.didSelect { [unowned self] in
            self.toast.didTap()
            self.dismiss()
        }

        Task {
            await Task.snooze(seconds: 0.1)
            self.update(for: self.state)
            self.didPrepareForPresentation()
        }

        #if !NOTIFICATION
        guard let superview = UIWindow.topWindow() else { return }
        superview.addSubview(self)
        #endif
    }

    func reveal() {

    }

    func dismiss() {

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
            break 
        case .left:
            break
        case .expanded:
            break
        case .alphaIn:
            break
        case .dismiss:
            break
        case .gone:
            break
        }
        #endif

        self.layoutNow()
    }
}
