//
//  ReservationCell.swift
//  Ours
//
//  Created by Benji Dodgson on 1/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import TMROLocalization

class ReservationCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Reservation

    let button = Button()
    let imageView = UIImageView(image: UIImage(systemName: "person.badge.plus"))
    let avatarView = AvatarView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.button)
        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.avatarView)
        self.imageView.tintColor = Color.purple.color
        self.imageView.contentMode = .scaleAspectFit
    }

    func configure(with item: Reservation) {
        if let contactId = item.contactId, let contact = ContactsManger.shared.searchForContact(with: .identifier(contactId)).first {
            let text = LocalizedString(id: "", arguments: [contact.givenName], default: "Remind @(name)?")
            self.button.set(style: .normal(color: .purple, text: text))
            self.imageView.isHidden = true
            self.avatarView.set(avatar: contact)
            self.avatarView.isHidden = false
        } else {
            self.button.set(style: .normal(color: .purple, text: ""))
            self.imageView.isHidden = false
            self.avatarView.isHidden = true 
        }

        self.contentView.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.button.width = self.contentView.width * 0.95
        self.button.expandToSuperviewHeight()
        self.button.centerOnX()

        self.imageView.squaredSize = 24
        self.imageView.centerOnXAndY()

        let height = self.button.height - Theme.contentOffset.doubled
        self.avatarView.setSize(for: height)
        self.avatarView.match(.left, to: .left, of: self.button, offset: Theme.contentOffset)
        self.avatarView.centerOnY()
    }
}
