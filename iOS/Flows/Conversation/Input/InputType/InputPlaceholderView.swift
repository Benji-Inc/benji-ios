//
//  InputPlaceholderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InputPlaceholderView: BaseView {

    let label = ThemeLabel(font: .mediumBold)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.addSubview(self.label)
        self.label.textAlignment = .center

        self.set(backgroundColor: .background)
    }

    func configure(with type: InputType) {
        switch type {
        case .photo:
            self.label.setText("Photos coming soon.")
        case .video:
            self.label.setText("Videos coming soon.")
        case .keyboard:
            break
        case .calendar:
            self.label.setText("Calendar support coming soon.")
        case .jibs:
            self.label.setText("Wallet coming soon.")
        case .confirmation:
            break
        }

        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.width - Theme.contentOffset.doubled)
        self.label.centerOnXAndY()
    }
}
