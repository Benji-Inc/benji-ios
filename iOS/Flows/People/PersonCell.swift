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
    let buttonTitleLabel = ThemeLabel(font: .systemBold)
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
        if let user = item.connection?.nonMeUser {
            Task {
                await self.loadData(for: user, highlightText: item.highlightText)
            }.add(to: self.taskPool)
        } else {
            self.buttonTitleLabel.setText("Invite")
            self.updateName(for: item, highlightText: item.highlightText)
        }
    }
    
    @MainActor
    func loadData(for user: User, highlightText: String?) async {
        guard let userWithData = try? await user.retrieveDataIfNeeded(), !Task.isCancelled else { return }
        
        self.updateName(for: userWithData, highlightText: highlightText)
        self.buttonTitleLabel.setText("Add")
        self.layoutNow()
    }
    
    private func updateName(for avatar: Avatar, highlightText: String?) {
        self.titleLabel.setText(avatar.fullName)
        
        if let highlightText = highlightText {
            let attributes: [NSAttributedString.Key : Any] = [.font: FontType.systemBold.font,
                                                              .foregroundColor: ThemeColor.D6.color]
            self.titleLabel.add(attributes: attributes, to: highlightText)
        }

        self.layoutNow()
    }

    override func update(isSelected: Bool) {
        super.update(isSelected: isSelected)
        
        if let person = self.currentItem {
            if let _ = person.connection {
                if isSelected {
                    self.buttonTitleLabel.setText("Added")
                } else {
                    self.buttonTitleLabel.setText("Add")
                }
            } else {
                if isSelected {
                    self.buttonTitleLabel.setText("Added")
                } else {
                    self.buttonTitleLabel.setText("Invite")
                }
            }
        }
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.buttonTitleLabel.setTextColor(isSelected ? .D1 : .T1)
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
