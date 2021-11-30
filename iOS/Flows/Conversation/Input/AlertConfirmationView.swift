//
//  AlertConfirmationView.swift
//  Benji
//
//  Created by Benji Dodgson on 10/31/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class AlertConfirmationView: View {

    private let label = Label(font: .regular)
    let button = Button()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .white)

        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.addSubview(self.label)
        self.label.textAlignment = .center

        self.addSubview(self.button)
        self.button.set(style: .normal(color: .darkGray, text: "Cancel"))
    }

    func setAlertMessage(for avatars: [Avatar]) {
        var arguments: String = String()
        for (index, avatar) in avatars.enumerated() {
            if avatar.userObjectID != User.current()?.objectId {
                if avatars.count == 1 {
                    arguments += avatar.givenName + " "
                } else if index + 1 == avatars.count, arguments.count > 1 {
                    arguments += " and" + avatar.givenName + " "
                } else {
                    arguments += avatar.givenName + ", "
                }
            }
        }

        if arguments.isEmpty {
            arguments.append("others ")
        }
        let text = LocalizedString(id: "", arguments: [arguments], default: "Swipe up to notify @(arguments)of this message.")

        self.label.setText(text)
        self.label.add(attributes: [.font: FontType.regularBold.font], to: arguments)
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.width * 0.8)
        self.label.centerOnX()
        self.label.centerY = self.halfWidth * 0.6

        self.button.setSize(with: self.width)
        self.button.pinToSafeAreaBottom()
        self.button.centerOnX()
    }
}
