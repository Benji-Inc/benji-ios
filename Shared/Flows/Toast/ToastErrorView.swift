//
//  File.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ToastErrorView: View, ToastViewable {


    var toast: Toast?

    var didDismiss: () -> Void

    var didTap: () -> Void

    func reveal() {

    }

    func dismiss() {

    }

    func configure(toast: Toast) {

    }


    private let label = Label(font: .regular, textColor: .red)

    initializeSubviews()

}
