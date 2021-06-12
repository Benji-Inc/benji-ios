//
//  ProfileDetailCell.swift
//  Benji
//
//  Created by Benji Dodgson on 10/15/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class ProfileDetailView: View {
    
    let titleLabel = Label(font: .small)
    let label = Label(font: .smallBold)
    let button = Button()
    private var cancellables = Set<AnyCancellable>()

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

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
}
