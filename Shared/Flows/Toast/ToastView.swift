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
    var toast: Toast? { get set }
    var didDismiss: () -> Void { get set }
    var didTap: () -> Void { get set }
    func reveal()
    func dismiss()
    func configure(toast: Toast)
}

class ToastView: View, ToastViewable {

    var toast: Toast?
    var didDismiss: () -> Void = {}
    var didTap: () -> Void = {}

    var panStart: CGPoint?
    var startY: CGFloat?

    var maxHeight: CGFloat?
    var screenOffset: CGFloat = 50
    var presentationDuration: TimeInterval = 10.0

    var cancellables = Set<AnyCancellable>()

    @Published var state: ToastState = .hidden

    override func initializeSubviews() {
        super.initializeSubviews()

        self.$state.mainSink { [unowned self] state in
            self.update(for: state)
        }.store(in: &self.cancellables)
    }

    func configure(toast: Toast) {
        self.toast = toast
        self.didSelect { [unowned self] in
            toast.didTap()
            self.dismiss()
        }
    }

    func reveal() {

    }

    func dismiss() {

    }

    func update(for state: ToastState) {
        switch state {
        case .hidden:
            break
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
    }
}
