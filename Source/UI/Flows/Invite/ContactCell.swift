//
//  ContactCell.swift
//  Benji
//
//  Created by Benji Dodgson on 6/30/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts

class ContactCell: UICollectionViewCell {

    var onLongPress: (() -> Void)?

    let content = InviteableContentView()

    var showSelected: Bool? {
        didSet {
            guard let showSelected = self.showSelected, showSelected != oldValue else { return }

            if showSelected {
                self.content.animateToChecked()
            } else {
                self.content.animateToUnchecked()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initializeSubviews() {
        self.contentView.addSubview(self.content)
    }

    func configure(with item: CNContact?) {
        guard let contact = item else { return }

        self.content.configure(with: .contact(contact))
    }

    func update(isSelected: Bool) {
        self.showSelected = isSelected
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.content.expandToSuperviewSize()
    }
}
