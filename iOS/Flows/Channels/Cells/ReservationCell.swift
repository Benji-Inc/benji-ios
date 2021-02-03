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

class ReservationCell: CollectionViewManagerCell {

    let button = Button()
    let imageView = UIImageView(image: UIImage(systemName: "person.badge.plus"))
    private var cancellables = Set<AnyCancellable>()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.button)
        self.contentView.addSubview(self.imageView)
        self.imageView.tintColor = Color.purple.color
        self.imageView.contentMode = .scaleAspectFit
    }

    func configure(with reservation: Reservation) {

        if let contactId = reservation.contactId {
            ContactsManger.shared.searchForContact(with: .identifier(contactId))
                .mainSink { (result) in
                    switch result {
                    case .success(let contacts):
                        guard let contact = contacts.first, let name = contact.fullName else { return }
                        let text = LocalizedString(id: "", arguments: [name], default: "Remind @(name)?")
                        self.button.set(style: .normal(color: .purple, text: text))
                    case .error(_):
                        break
                    }
                }.store(in: &self.cancellables)
            self.imageView.isHidden = true
        } else {
            self.button.set(style: .normal(color: .purple, text: ""))
            self.imageView.isHidden = false
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
    }
}
