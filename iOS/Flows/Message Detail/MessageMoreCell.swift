//
//  MessageMoreCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/29/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

struct MoreOptionModel: Hashable {
    var message: Message
    var option: MessageDetailDataSource.OptionType
}

class MessageMoreCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = MoreOptionModel
    
    var currentItem: MoreOptionModel?
    
    let imageView = UIImageView()
    let label = ThemeLabel(font: .regular)
    let button = ThemeButton()
    
    var didTapEdit: CompletionOptional = nil
    var didTapDelete: CompletionOptional = nil
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.set(backgroundColor: .B6)
        self.contentView.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.tintColor = ThemeColor.T1.color
        self.contentView.addSubview(self.label)
        self.label.textAlignment = .center
        
        self.contentView.layer.cornerRadius = Theme.cornerRadius
        self.contentView.layer.masksToBounds = true
        
        self.contentView.addSubview(self.button)
    }
    
    func configure(with item: MoreOptionModel) {
        self.imageView.image = item.option.image
        self.label.setText(item.option.title)
        self.button.menu = self.makeContextMenu(for: item.message)
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = self.height * 0.3
        self.imageView.centerOnX()
        self.imageView.bottom = self.contentView.centerY
        
        self.label.setSize(withWidth: self.contentView.width)
        self.label.centerOnX()
        self.label.match(.top, to: .bottom, of: self.imageView, offset: .standard)
        
        self.button.expandToSuperviewSize()
    }
    
    private func makeContextMenu(for message: Message) -> UIMenu {

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { action in }

        let confirmDelete = UIAction(title: "Confirm",
                                     image: UIImage(systemName: "trash"),
                                     attributes: .destructive) { action in
            self.didTapDelete?()
        }

        let deleteMenu = UIMenu(title: "Delete Message",
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirmDelete, neverMind])

        let edit = UIAction(title: "Edit",
                            image: UIImage(systemName: "pencil.circle")) { [unowned self] action in
            self.didTapEdit?()
        }

        let read = UIAction(title: "Set to read",
                            image: UIImage(systemName: "eyeglasses")) { [unowned self] action in
            self.setToRead(with: message)
        }

        let unread = UIAction(title: "Set to unread",
                            image: UIImage(systemName: "eyeglasses")) { [unowned self] action in
            self.setToUnread(with: message)
        }

        var menuElements: [UIMenuElement] = []

        if message.isFromCurrentUser {
            menuElements.append(deleteMenu)
        }

        if message.isFromCurrentUser {
            menuElements.append(edit)
        }

        if message.isConsumedByMe {
            menuElements.append(unread)
        } else if message.canBeConsumed {
            menuElements.append(read)
        }

        return UIMenu.init(title: "More",
                           image: nil,
                           identifier: nil,
                           options: [],
                           children: menuElements)
    }
    
    // MARK: - Message Consumption

    func setToRead(with message: Message) {
        guard message.canBeConsumed else { return }
        Task {
            try await message.setToConsumed()
        }
    }

    func setToUnread(with message: Message) {
        guard message.isConsumedByMe else { return }
        Task {
            try await message.setToUnconsumed()
        }
    }

}
