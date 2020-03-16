//
//  AlertView.swift
//  Benji
//
//  Created by Benji Dodgson on 6/30/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AlertView: View {

    private(set) var containerView = UIView()
    private(set) var buttonsContainer = UIView()
    private(set) var buttons: [Button] = []

    override func initializeSubviews() {

        super.initializeSubviews()

        self.addSubview(self.containerView)
        self.addSubview(self.buttonsContainer)
        self.set(backgroundColor: .background2)
        self.buttonsContainer.set(backgroundColor: .clear)
    }

    func configure(buttons: [Button]) {

        self.buttons.removeAllFromSuperview(andRemoveAll: true)
        self.buttons = buttons
        self.buttons.forEach { button in
            self.buttonsContainer.addSubview(button)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.showShadow(withOffset: 5)
    }
}
