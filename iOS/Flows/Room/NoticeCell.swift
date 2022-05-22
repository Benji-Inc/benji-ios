//
//  NoticeCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/1/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class NoticeCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = SystemNotice
    
    var currentItem: SystemNotice?
    
    private let titleLabel = ThemeLabel(font: .mediumBold, textColor: .white)
    private let descriptionLabel = ThemeLabel(font: .regular, textColor: .white)
    private let imageView = BorderedPersonView()
    
    private let rightButtonLabel = ThemeLabel(font: .regularBold)
    private let leftButtonLabel = ThemeLabel(font: .regular)
    
    var didTapRightButton: CompletionOptional = nil
    var didTapLeftButton: CompletionOptional = nil
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.set(backgroundColor: .B6)
        self.contentView.layer.cornerRadius = Theme.cornerRadius
        
        self.contentView.addSubview(self.imageView)
        
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.descriptionLabel)
        
        self.contentView.addSubview(self.rightButtonLabel)
        self.rightButtonLabel.isUserInteractionEnabled = true
        self.rightButtonLabel.didSelect { [unowned self] in
            self.didTapRightButton?()
        }
        
        self.contentView.addSubview(self.leftButtonLabel)
        self.leftButtonLabel.isUserInteractionEnabled = true 
        self.leftButtonLabel.didSelect { [unowned self] in
            self.didTapLeftButton?()
        }
        self.leftButtonLabel.alpha = 0.25
    }

    func configure(with item: SystemNotice) {
        Task {
            await self.handle(notice: item)
        }
    }
    
    @MainActor
    private func handle(notice: SystemNotice) async {
        
        self.titleLabel.setText(notice.type.title)
        self.descriptionLabel.setText(notice.body ?? "")
        
        switch notice.type {
        case .timeSensitiveMessage:
            guard let cidValue = notice.attributes?["cid"] as? String,
                  let cid = try? ChannelId(cid: cidValue),
                  let messageId = notice.attributes?["messageId"] as? String else {
                self.showError()
                return }
            
            let controller = ChatClient.shared.messageController(cid: cid, messageId: messageId)
            try? await controller.synchronize()
            
            guard let message = controller.message,
                  let author = await PeopleStore.shared.getPerson(withPersonId: message.author.personId) else {
                self.showError()
                return
            }
            
            self.titleLabel.setText("\(author.givenName.firstCapitalized) said:")
            self.descriptionLabel.setText(message.text)
            self.rightButtonLabel.setText("View")
            self.leftButtonLabel.setText("")
            self.imageView.set(person: author)
        case .connectionRequest:
            guard let connectionId = notice.attributes?["connectionId"] as? String,
                  let connection = PeopleStore.shared.allConnections.first(where: { existing in
                      return existing.objectId == connectionId
                  }) else {
                self.showError()
                return }
            self.imageView.set(person: connection.nonMeUser)
            self.rightButtonLabel.setText("Accept")
            self.leftButtonLabel.setText("Decline")
        case .connectionConfirmed:
            guard let connectionId = notice.attributes?["connectionId"] as? String,
                  let connection = PeopleStore.shared.allConnections.first(where: { existing in
                      return existing.objectId == connectionId
                  }) else { self.showError()
                return }
            
            self.imageView.set(person: connection.nonMeUser)
            self.rightButtonLabel.setText("Ok")
            self.leftButtonLabel.setText("")

        case .unreadMessages:
            let count = notice.notice?.unreadMessages.count ?? 0
            
            if count == 0 {
                let text = "You are all caught up! 🥳"
                self.descriptionLabel.setText(text)
                self.rightButtonLabel.setText("")
                self.leftButtonLabel.setText("")
            } else {
                let text = "You have \(notice.notice?.unreadMessages.count ?? 0) unread messages."
                self.descriptionLabel.setText(text)
                self.rightButtonLabel.setText("")
                self.leftButtonLabel.setText("")
            }
            
        case .system:
            self.descriptionLabel.alpha = 0.25
        }
        
        self.imageView.isVisible = !self.imageView.displayable.isNil
        
        self.setNeedsLayout()
    }
    
    func showError() {
        self.imageView.isVisible = false 
        self.titleLabel.setText("Error")
        self.descriptionLabel.setText("There was an error displaying this content.")
        self.rightButtonLabel.setText("")
        self.leftButtonLabel.setText("")
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let padding = Theme.ContentOffset.xtraLong

        self.imageView.setSize(forHeight: 38)
        self.imageView.pin(.left, offset: padding)
        self.imageView.pin(.top, offset: padding)
        
        var maxTitleWidth = self.width - (self.imageView.right + padding.value.doubled)
        if self.imageView.displayable.isNil {
            maxTitleWidth = self.width - padding.value.doubled
        }

        self.titleLabel.setSize(withWidth: maxTitleWidth)
        if self.imageView.displayable.isNil {
            self.titleLabel.pin(.left, offset: padding)
        } else {
            self.titleLabel.match(.left, to: .right, of: self.imageView, offset: padding)
        }
        self.titleLabel.match(.top, to: .top, of: self.imageView)

        self.descriptionLabel.setSize(withWidth: maxTitleWidth)
        self.descriptionLabel.match(.left, to: .left, of: self.titleLabel)
        self.descriptionLabel.match(.top, to: .bottom, of: self.titleLabel, offset: .short)
        
        self.rightButtonLabel.setSize(withWidth: self.width)
        self.rightButtonLabel.pin(.right, offset: padding)
        self.rightButtonLabel.pin(.bottom, offset: padding)
        
        self.leftButtonLabel.setSize(withWidth: self.width)
        self.leftButtonLabel.match(.right, to: .left, of: self.rightButtonLabel, offset: .negative(.xtraLong))
        self.leftButtonLabel.pin(.bottom, offset: padding)
    }
}
