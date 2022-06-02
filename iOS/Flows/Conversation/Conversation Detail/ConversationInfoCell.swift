//
//  ConversationInfoCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class ConversationInfoCell: CollectionViewManagerCell, ManageableCell {
    
    var currentItem: String?

    private let topicLabel = ThemeLabel(font: .mediumBold)
    private let dateLabel = ThemeLabel(font: .small)
    
    private var controller: ConversationController?

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.topicLabel)
        self.contentView.addSubview(self.dateLabel)
        self.dateLabel.alpha = 0.25
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.topicLabel.setSize(withWidth: self.width)
        self.topicLabel.pin(.left)
        self.topicLabel.pin(.top, offset: .long)

        self.dateLabel.setSize(withWidth: self.width)
        self.dateLabel.pin(.left)
        self.dateLabel.pin(.bottom, offset: .short)
    }
    
    func configure(with item: String) {
        self.controller = JibberChatClient.shared.conversationController(for: item)
        
        guard let conversation = self.controller?.conversation else { return }
        Task {
            await self.update(with: conversation)
        }
        self.subscribeToUpdates()
    }
    
    @MainActor
    private func update(with conversation: Conversation) async {
        let dateString = Date.monthDayYear.string(from: conversation.createdAt)
        
        guard let person = await PeopleStore.shared.getPerson(withPersonId: conversation.authorId) else { return }
        
        self.dateLabel.setText("Created by \(person.givenName) on \(dateString)")
        self.setTopic(for: conversation)
        
        self.layoutNow()
    }
    
    private func setTopic(for conversation: Conversation) {
        if let title = conversation.title {
            self.topicLabel.setText(title)
        } else {
            // If there is no title, then list the members of the conversation.
            let members = conversation.lastActiveMembers.filter { member in
                return !member.isCurrentUser
            }

            var membersString = ""
            members.forEach { member in
                if membersString.isEmpty {
                    membersString = member.givenName
                } else {
                    membersString.append(", \(member.givenName)")
                }
            }
            
            if membersString.isEmpty {
                self.topicLabel.setText("No Topic")
            } else {
                self.topicLabel.setText(membersString)
            }
        }
    }
    
    private func subscribeToUpdates() {
        self.controller?
            .channelChangePublisher
            .mainSink { [unowned self] event in
                switch event {
                case .create(_):
                    break
                case .update(let conversation):
                    Task {
                        await self.update(with: conversation)
                    }
                case .remove(_):
                    break
                }
            }.store(in: &self.cancellables)
    }
}
