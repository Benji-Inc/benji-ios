//
//  ToastView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

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

    func configure(toast: Toast) {
        
    }

    func reveal() {

    }

    func dismiss() {

    }
}
