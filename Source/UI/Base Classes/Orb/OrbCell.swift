//
//  OrbCell.swift
//  Benji
//
//  Created by Benji Dodgson on 12/28/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class OrbCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = User

    let label = RegularBoldLabel()
    let imageView = AvatarView()
    let selectionFeedback = UIImpactFeedbackGenerator()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.layer.cornerRadius = Theme.cornerRadius
        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.label)

        self.imageView.isUserInteractionEnabled = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.size = CGSize(width: 90, height: 120)
        self.imageView.top = 0
        self.imageView.centerOnX()

        self.label.setSize(withWidth: 140)
        self.label.bottom = self.contentView.height - 10
        self.label.centerOnX()
    }

    func configure(with item: User?) {
        guard let user = item else { return }

        user.fetchIfNeededInBackground { (object, error) in
            guard let fullUser = object as? User else { return }

            self.imageView.set(avatar: fullUser)

            let displayName: Localized = fullUser.firstAndLastInitial ?? fullUser.fullName
            self.label.set(text: displayName,
                           color: .white,
                           alignment: .center,
                           stringCasing: .lowercase)
            self.setNeedsLayout()
        }
    }

    func update(isSelected: Bool) {
        self.imageView.alpha = isSelected ? 1.0 : 0.3
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.imageView.alpha = 0.3
        self.label.text = String()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.selectionFeedback.impactOccurred()
    }
}
