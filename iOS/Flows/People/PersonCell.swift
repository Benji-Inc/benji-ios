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

    let personView = BorderedPersonView()
    let titleLabel = ThemeLabel(font: .regular)
    let lineView = BaseView()
    
    private let imageView = UIImageView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.tintColor = ThemeColor.white.color
        
        self.contentView.addSubview(self.personView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.lineView)
        
        self.lineView.set(backgroundColor: .B1)
        self.lineView.alpha = 0.5
    }
    
    func configure(with item: Person) {
        self.currentItem = item
        
        self.personView.isVisible = !item.user.isNil
        
        if let user = item.user {
            self.personView.set(person: user)
            self.updateName(for: user, highlightText: item.highlightText)
            self.titleLabel.setTextColor(.white)
        } else {
            self.titleLabel.setTextColor(.white)
            self.updateName(for: item, highlightText: item.highlightText)
        }
        
        self.imageView.image = UIImage(systemName: "person.crop.circle.badge.plus")
        self.handle(isSelected: item.isSelected)
    }
    
    private func updateName(for person: PersonType, highlightText: String?) {
        self.titleLabel.setText(person.fullName)
        
        if let highlightText = highlightText {
            let attributes: [NSAttributedString.Key : Any] = [.font: FontType.regularBold.font,
                                                              .foregroundColor: ThemeColor.white.color]
            self.titleLabel.add(attributes: attributes, to: highlightText)
        }

        self.layoutNow()
    }
    
    private func handle(isSelected: Bool) {
        
        if let person = self.currentItem {
            if let _ = person.user {
                if isSelected {
                    self.imageView.image = UIImage(systemName: "person.crop.circle.fill.badge.checkmark")
                } else {
                    self.imageView.image = UIImage(systemName: "person.crop.circle.badge.plus")
                }
            } else {
                if isSelected {
                    self.imageView.image = UIImage(systemName: "person.crop.circle.fill.badge.checkmark")
                } else {
                    self.imageView.image = UIImage(systemName: "person.crop.circle.badge.plus")
                }
            }
        }
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.titleLabel.alpha = isSelected ? 1.0 : 0.5
            self.imageView.alpha = isSelected ? 1.0 : 0.5
            self.setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.titleLabel.setSize(withWidth: self.contentView.width)
        self.titleLabel.centerOnY()
        
        if self.personView.isVisible {
            self.personView.squaredSize = 30
            self.personView.pinToSafeAreaLeft()
            self.personView.centerOnY()
            self.titleLabel.match(.left, to: .right, of: self.personView, offset: .long)
        } else {
            self.titleLabel.pinToSafeAreaLeft()
        }
        
        self.imageView.squaredSize = 24
        self.imageView.pinToSafeAreaRight()
        self.imageView.centerOnY()
        
        self.lineView.height = 1
        self.lineView.expandToSuperviewWidth()
        self.lineView.pin(.bottom)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.titleLabel.text = nil
    }
}
