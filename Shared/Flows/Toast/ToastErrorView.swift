//
//  File.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ToastErrorView: View, ToastViewable {

    private let label = Label(font: .smallBold, textColor: .red)

    var toast: Toast?
    var didDismiss: () -> Void = {}
    var didTap: () -> Void = {}

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.label)
    }

    func configure(toast: Toast) {
        self.toast = toast
    }

    func reveal() {

    }

    func dismiss() {

    }

    override func layoutSubviews() {
        super.layoutSubviews()

        
    }
}
