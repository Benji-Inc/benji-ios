//
//  ConnectionCell.swift
//  Ours
//
//  Created by Benji Dodgson on 1/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class ConnectionCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = Connection

    private let vibrancyView = VibrancyView()
    private let containerView = View()

    private let avatarView = AvatarView()
    private let descriptionLabel = Label(font: .regular, textColor: .white)

    private let acceptButton = Button()
    private let declineButton = Button()

    var didSelectStatus: ((Connection.Status) -> Void)? = nil

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.containerView)
        self.containerView.addSubview(self.vibrancyView)
        self.containerView.addSubview(self.descriptionLabel)
        self.containerView.addSubview(self.avatarView)
        self.containerView.addSubview(self.acceptButton)
        self.acceptButton.set(style: .normal(color: .green, text: "Accept"))
        self.acceptButton.didSelect { [unowned self] in
            self.didSelectStatus?(.accepted)
        }
        self.containerView.addSubview(self.declineButton)
        self.declineButton.set(style: .normal(color: .red, text: "Decline"))
        self.declineButton.didSelect { [unowned self] in
            self.didSelectStatus?(.declined)
        }

        self.set(backgroundColor: .clear)
        self.containerView.roundCorners()
    }

    func configure(with item: Connection) {
        guard let status = item.status, status == .invited, let user = item.nonMeUser else { return }

        let text = LocalizedString(id: "", arguments: [user.handle], default: "@(handle) has invited you to connect.")
        self.descriptionLabel.setText(text)
        self.avatarView.set(avatar: user)

        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.containerView.width = self.contentView.width * 0.95
        self.containerView.expandToSuperviewHeight()
        self.containerView.centerOnX()

        self.vibrancyView.expandToSuperviewSize()

        self.avatarView.left = Theme.contentOffset
        self.avatarView.top = Theme.contentOffset
        self.avatarView.setSize(for: 40)

        let maxLabelWidth = self.containerView.width - self.avatarView.right - (Theme.contentOffset * 2)
        self.descriptionLabel.setSize(withWidth: maxLabelWidth)
        self.descriptionLabel.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset)
        self.descriptionLabel.match(.top, to: .top, of: self.avatarView)

        let buttonWidth = self.containerView.halfWidth - (Theme.contentOffset * 2)

        self.acceptButton.size = CGSize(width: buttonWidth, height: 40)
        self.acceptButton.pin(.right, padding: Theme.contentOffset)
        self.acceptButton.pin(.bottom, padding: Theme.contentOffset)

        self.declineButton.size = CGSize(width: buttonWidth, height: 40)
        self.declineButton.pin(.left, padding: Theme.contentOffset)
        self.declineButton.pin(.bottom, padding: Theme.contentOffset)
    }
}
