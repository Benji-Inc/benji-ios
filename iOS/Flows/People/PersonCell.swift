//
//  PersonCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts
import PhoneNumberKit

class PersonCell: CollectionViewManagerCell, ManageableCell {
    
    var currentItem: Person?
    
    typealias ItemType = Person

    let titleLabel = ThemeLabel(font: .system)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.titleLabel)
    }
    
    func configure(with item: Person) {
        if let user = item.connection?.nonMeUser {
            Task {
                await self.loadData(for: user)
            }
        } else {
            self.titleLabel.setText(item.fullName)
            self.layoutNow()
        }
    }
    
    @MainActor
    func loadData(for user: User) async {
        guard let userWithData = try? await user.retrieveDataIfNeeded() else { return }
        self.titleLabel.setText(userWithData.fullName)
        self.layoutNow()
    }

    override func update(isSelected: Bool) {
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.titleLabel.setTextColor(isSelected ? .D1 : .T1)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.titleLabel.setSize(withWidth: self.contentView.width)
        self.titleLabel.centerOnY()
        self.titleLabel.pin(.left)
    }
}
