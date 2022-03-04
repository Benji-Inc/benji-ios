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
    let buttonTitleLabel = ThemeLabel(font: .systemBold, textColor: .D1)
    let lineView = BaseView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.buttonTitleLabel)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.lineView)
        
        self.lineView.set(backgroundColor: .B4)
        self.lineView.alpha = 0.5
    }
    
    func configure(with item: Person) {
        self.currentItem = item
        
        if let user = item.user {
            self.updateName(for: user, highlightText: item.highlightText)
            self.buttonTitleLabel.setText("Add")
            self.titleLabel.setTextColor(.D1)
            self.buttonTitleLabel.setTextColor(.D1)
        } else {
            self.titleLabel.setTextColor(.T1)
            self.buttonTitleLabel.setText("Invite")
            self.buttonTitleLabel.setTextColor(.T1)
            self.updateName(for: item, highlightText: item.highlightText)
        }
        
        self.handle(isSelected: item.isSelected)
    }
    
    private func updateName(for person: PersonType, highlightText: String?) {
        self.titleLabel.setText(person.fullName)
        
        if let highlightText = highlightText {
            let attributes: [NSAttributedString.Key : Any] = [.font: FontType.systemBold.font,
                                                              .foregroundColor: ThemeColor.D6.color]
            self.titleLabel.add(attributes: attributes, to: highlightText)
        }

        self.layoutNow()
    }
    
    private func handle(isSelected: Bool) {
        var color: ThemeColor = isSelected ? .D1 : .T1
        
        if let person = self.currentItem {
            if let _ = person.user {
                if isSelected {
                    self.buttonTitleLabel.setText("Added")
                } else {
                    self.buttonTitleLabel.setText("Add")
                }
                color = .D1
            } else {
                if isSelected {
                    self.buttonTitleLabel.setText("Added")
                } else {
                    self.buttonTitleLabel.setText("Invite")
                }
            }
        }
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.buttonTitleLabel.setTextColor(color)
            self.setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.titleLabel.setSize(withWidth: self.contentView.width)
        self.titleLabel.centerOnY()
        self.titleLabel.pin(.left, offset: .xtraLong)
        
        self.buttonTitleLabel.setSize(withWidth: self.contentView.width)
        self.buttonTitleLabel.centerOnY()
        self.buttonTitleLabel.pin(.right, offset: .xtraLong)
        
        self.lineView.height = 1
        self.lineView.expandToSuperviewWidth()
        self.lineView.pin(.bottom)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.buttonTitleLabel.text = nil
        self.titleLabel.text = nil
    }
}
