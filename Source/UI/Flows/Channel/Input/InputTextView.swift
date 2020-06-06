//
//  InputTextView.swift
//  Benji
//
//  Created by Benji Dodgson on 7/2/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InputTextView: TextView {

    lazy var countView = CharacterCountView()
    var textDidChange: ((String) -> Void)?

    override func initialize() {
        super.initialize()

        self.translatesAutoresizingMaskIntoConstraints = false
        self.textContainer.heightTracksTextView = true
        self.isScrollEnabled = false
        self.keyboardType = .twitter
        self.tintColor = Color.white.color

        self.textContainerInset.left = 10
        self.textContainerInset.right = 10
        self.textContainerInset.top = 14
        self.textContainerInset.bottom = 12

        self.addSubview(self.countView)
        self.countView.isHidden = true

        self.set(backgroundColor: .clear)
    }

    func setPlaceholder(for avatars: [Avatar]) {
        var placeholderText = "Message "

        for (index, avatar) in avatars.enumerated() {
            if index < avatars.count - 1 {
                placeholderText.append(String("\(avatar.givenName), "))
            } else if index == avatars.count - 1 && avatars.count > 1 {
                placeholderText.append(String("and \(avatar.givenName)"))
            } else {
                placeholderText.append(avatar.givenName)
            }
        }

        self.set(placeholder: placeholderText, color: .lightPurple)
    }

    override func textDidChange(notification: Notification) {
        self.textDidChange?(self.text)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.countView.size = CGSize(width: 70, height: 20)
        self.countView.right = self.width - 5
        self.countView.bottom = self.height - 5
    }
}
