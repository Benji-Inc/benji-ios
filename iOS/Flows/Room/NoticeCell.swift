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
    
    lazy var connectionConfirmedConentView = ConnectionConfirmedContentView()
    lazy var connectionRequestContentView = ConnectionRequestContentView()
    lazy var invitePromptContentView = InvitePromptContentView()
    lazy var introContentView = JibberIntroContentView()
    lazy var tipContentView = TipContentView()
    lazy var urgentMessageContentView = UrgentMessageContentView() 
    
    var didSelectPrimaryOption: CompletionOptional = nil
    var didSelectSecondaryOption: CompletionOptional = nil

    func configure(with item: SystemNotice) {
        Task {
            await self.handle(notice: item)
        }
    }
    
    @MainActor
    private func handle(notice: SystemNotice) async {
        self.contentView.removeAllSubviews()
        
        let content: NoticeContentView
        
        switch notice.type {
        case .timeSensitiveMessage:
            content = self.urgentMessageContentView
        case .connectionRequest:
            content = self.connectionRequestContentView
        case .connectionConfirmed:
            content = self.connectionConfirmedConentView
        case .tip:
            content = self.tipContentView
        case .invitePrompt:
            content = self.invitePromptContentView
        case .jibberIntro:
            content = self.invitePromptContentView
        case .system, .unreadMessages:
            content = NoticeContentView()
        }
        
        content.configure(for: notice)
        self.contentView.addSubview(content)
                
//        switch notice.type {
//        case .timeSensitiveMessage:
//            guard let cidValue = notice.attributes?["cid"] as? String,
//                  let cid = try? ChannelId(cid: cidValue),
//                  let messageId = notice.attributes?["messageId"] as? String else {
//                self.showError()
//                return }
//
//            let controller = ChatClient.shared.messageController(cid: cid, messageId: messageId)
//            try? await controller.synchronize()
//
//            guard let message = controller.message,
//                  let author = await PeopleStore.shared.getPerson(withPersonId: message.author.personId) else {
//                self.showError()
//                return
//            }
//
//            self.titleLabel.setText("Urgent Message")
//            self.descriptionLabel.setText(message.text)
//            self.rightButtonLabel.setText("View")
//            self.leftButtonLabel.setText("")
//            self.imageView.set(person: author)
//        case .connectionRequest:
//            guard let connectionId = notice.attributes?["connectionId"] as? String,
//                  let connection = PeopleStore.shared.allConnections.first(where: { existing in
//                      return existing.objectId == connectionId
//                  }) else {
//                self.showError()
//                return }
//            self.imageView.set(person: connection.nonMeUser)
//            self.rightButtonLabel.setText("Accept")
//            self.leftButtonLabel.setText("Decline")
//        case .connectionConfirmed:
//            guard let connectionId = notice.attributes?["connectionId"] as? String,
//                  let connection = PeopleStore.shared.allConnections.first(where: { existing in
//                      return existing.objectId == connectionId
//                  }) else { self.showError()
//                return }
//
//            self.imageView.set(person: connection.nonMeUser)
//            self.rightButtonLabel.setText("Ok")
//            self.leftButtonLabel.setText("")
//
//        case .unreadMessages:
//            let count = notice.notice?.unreadMessages.count ?? 0
//
//            if count == 0 {
//                let text = "You are all caught up! 🥳"
//                self.descriptionLabel.setText(text)
//                self.rightButtonLabel.setText("")
//                self.leftButtonLabel.setText("")
//            } else {
//                let text = "You have \(notice.notice?.unreadMessages.count ?? 0) unread messages."
//                self.descriptionLabel.setText(text)
//                self.rightButtonLabel.setText("")
//                self.leftButtonLabel.setText("")
//            }
//
//        case .system:
//            self.descriptionLabel.alpha = 0.25
//        case .tip:
//            break
//        case .invitePrompt:
//            break
//        case .jibberIntro:
//            break
//        }
//
//        self.imageView.isVisible = !self.imageView.displayable.isNil
        
        self.setNeedsLayout()
    }
    
    func showError() {
//        self.imageView.isVisible = false
//        self.titleLabel.setText("Error")
//        self.descriptionLabel.setText("There was an error displaying this content.")
//        self.rightButtonLabel.setText("")
//        self.leftButtonLabel.setText("")
//        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let first = self.contentView.subviews.first(where: { view in
            return view is NoticeContentView
        }) {
            first.expandToSuperviewSize()
        }
        
//        let padding = Theme.ContentOffset.xtraLong
//
//        self.imageView.setSize(forHeight: 38)
//        self.imageView.pin(.left, offset: padding)
//        self.imageView.pin(.top, offset: padding)
//
//        var maxTitleWidth = self.width - (self.imageView.right + padding.value.doubled)
//        if self.imageView.displayable.isNil {
//            maxTitleWidth = self.width - padding.value.doubled
//        }
//
//        self.titleLabel.setSize(withWidth: maxTitleWidth)
//        if self.imageView.displayable.isNil {
//            self.titleLabel.pin(.left, offset: padding)
//        } else {
//            self.titleLabel.match(.left, to: .right, of: self.imageView, offset: padding)
//        }
//        self.titleLabel.match(.top, to: .top, of: self.imageView)
//
//        self.descriptionLabel.setSize(withWidth: maxTitleWidth)
//        self.descriptionLabel.match(.left, to: .left, of: self.titleLabel)
//        self.descriptionLabel.match(.top, to: .bottom, of: self.titleLabel, offset: .short)
//
//        self.rightButtonLabel.setSize(withWidth: self.width)
//        self.rightButtonLabel.pin(.right, offset: padding)
//        self.rightButtonLabel.pin(.bottom, offset: padding)
//
//        self.leftButtonLabel.setSize(withWidth: self.width)
//        self.leftButtonLabel.match(.right, to: .left, of: self.rightButtonLabel, offset: .negative(.xtraLong))
//        self.leftButtonLabel.pin(.bottom, offset: padding)
    }
}
