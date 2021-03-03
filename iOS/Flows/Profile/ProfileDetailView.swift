//
//  ProfileDetailCell.swift
//  Benji
//
//  Created by Benji Dodgson on 10/15/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ProfileDetailView: View {
    
    let titleLabel = Label(font: .small)
    let label = Label(font: .smallBold)
    let button = Button()

    override func initializeSubviews() {
        super.initializeSubviews()
        self.addSubview(self.titleLabel)
        self.addSubview(self.label)
        self.addSubview(self.button)
        self.button.isHidden = true
    }

    func configure(with item: ProfileItem, for user: User) {

        self.button.isHidden = true

        switch item {
        case .picture:
            break
        case .name:
            self.titleLabel.setText("Name")
            self.label.setText(user.fullName)
        case .handle:
            self.titleLabel.setText("Handle")
            self.label.setText(user.handle)
        case .localTime:
            self.titleLabel.setText("Local Time")
            self.label.setText(Date.nowInLocalFormat)
        case .ritual:
            self.titleLabel.setText("Ritual")
            self.getRitual(for: user)
        }

        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.titleLabel.size = CGSize(width: self.width - Theme.contentOffset, height: 20)
        self.titleLabel.left = 0
        self.titleLabel.top = 0

        self.label.size = self.titleLabel.size
        self.label.left = self.titleLabel.left
        self.label.top = self.titleLabel.bottom + 5

        self.button.size = CGSize(width: 100, height: 40)
        self.button.bottom = self.label.bottom
        self.button.pin(.right)
    }

    private func getRitual(for user: User) {

        self.label.setText("NO RITUAL SET")
        self.button.set(style: .normal(color: .lightPurple, text: "Set"))
        self.button.isHidden = false

        user.ritual?.fetchIfNeededInBackground(block: { (object, error) in
            if let ritual = object as? Ritual, let date = ritual.date {
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                let string = formatter.string(from: date)
                self.label.setText(string)
                self.button.set(style: .normal(color: .lightPurple, text: "EDIT"))
            }

            self.layoutNow()
        })
    }
}
