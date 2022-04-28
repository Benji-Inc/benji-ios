//
//  ConversationHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine
import Lottie
import UIKit

class ConversationHeaderViewController: ViewController, ActiveConversationable {

    let button = ThemeButton()
    let topicLabel = ThemeLabel(font: .regularBold)
    let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.down"))
    let jibImageView = UIImageView(image: UIImage(named: "jiblogo"))
    let membersLabel = ThemeLabel(font: .small)
    let roomsButton = RoomNavigationButton()
    
    private var state: ConversationUIState = .read
        
    override func initializeViews() {
        super.initializeViews()

        self.view.clipsToBounds = false
        self.view.addSubview(self.button)
        
        self.view.addSubview(self.jibImageView)
        self.jibImageView.contentMode = .scaleToFill
        self.jibImageView.isUserInteractionEnabled = true 
        
        self.view.addSubview(self.topicLabel)
        self.topicLabel.textAlignment = .center
        
        self.view.addSubview(self.chevronImageView)
        self.chevronImageView.tintColor = ThemeColor.white.color
        self.chevronImageView.contentMode = .scaleAspectFit
        
        self.view.addSubview(self.membersLabel)
        self.membersLabel.textAlignment = .center
        
        self.view.addSubview(self.roomsButton)
        self.roomsButton.configure(for: .inner)
                        
        ConversationsManager.shared.$activeConversation
            .removeDuplicates()
            .mainSink { [unowned self] conversation in
                guard let convo = conversation else {
                    self.topicLabel.isVisible = false
                    self.membersLabel.isVisible = false
                    self.chevronImageView.isVisible = false
                    return
                }
                
                self.startLoadDataTask(with: conversation)
                
                self.setTopic(for: convo)
                self.membersLabel.isVisible = true
                self.topicLabel.isVisible = true
                self.chevronImageView.isVisible = true
                self.view.setNeedsLayout()
            }.store(in: &self.cancellables)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.jibImageView.squaredSize = 44
        self.jibImageView.pin(.right, offset: .custom(6))
        self.jibImageView.centerOnY()
        
        self.topicLabel.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.topicLabel.centerOnX()
        self.topicLabel.bottom = self.jibImageView.centerY - 2
        
        self.membersLabel.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.membersLabel.centerOnX()
        self.membersLabel.top = self.jibImageView.centerY + 2
        
        self.chevronImageView.squaredSize = self.membersLabel.height * 0.8
        self.chevronImageView.match(.left, to: .right, of: self.membersLabel, offset: .short)
        self.chevronImageView.match(.bottom, to: .bottom, of: self.membersLabel)
        
        self.button.height = self.view.height
        self.button.width = 200
        self.button.centerOnXAndY()
        
        self.roomsButton.pin(.left, offset: .custom(6))
        self.roomsButton.centerY = self.jibImageView.centerY
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
    
    func update(for state: ConversationUIState) {
        self.state = state
        
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.view.layoutNow()
        } completion: { completed in
            
        }
    }
    
    // Mark: Members
    
    var conversationController: ConversationController?
    
    /// A task for loading data and subscribing to conversation updates.
    private var loadDataTask: Task<Void, Never>?
    
    private func startLoadDataTask(with conversation: Conversation?) {
        self.loadDataTask?.cancel()

        if let cid = conversation?.cid {
            self.conversationController = ConversationController.controller(cid)
        } else {
            self.conversationController = nil
        }

        self.loadDataTask = Task { [weak self] in
            guard let conversationController = self?.conversationController else {
                // If there's no current conversation, then there's nothing to show.
                return
            }

            self?.setMembers(for: conversationController.conversation)

            guard !Task.isCancelled else { return }

            self?.subscribeToUpdates(for: conversationController)
        }
    }
    
    /// A task for loading data and subscribing to conversation updates.
    private var loadPeopleTask: Task<Void, Never>?
    
    private func setMembers(for conversation: Conversation?) {
        guard let conversation = conversation else {
            return
        }
        self.loadPeopleTask?.cancel()
        
        self.loadPeopleTask = Task { [weak self] in
            let members = await PeopleStore.shared.getPeople(for: conversation)
            if members.count == 0 {
                self?.membersLabel.setText("Just You")
            } else if members.count == 1 {
                self?.membersLabel.setText("1 Member")
            } else {
                self?.membersLabel.setText("\(members.count) Members")
            }
            self?.view.setNeedsLayout()
        }
    }

    /// The subscriptions for the current conversation.
    private var conversationCancellables = Set<AnyCancellable>()

    private func subscribeToUpdates(for conversationController: ConversationController) {
        // Clear out previous subscriptions.
        self.conversationCancellables.removeAll()

        conversationController
            .memberEventPublisher
            .mainSink(receiveValue: { [unowned self] event in
                switch event as MemberEvent {
                case _ as MemberAddedEvent:
                    self.setMembers(for: conversationController.conversation)
                case _ as MemberRemovedEvent:
                    guard let conversationController = self.conversationController else { return }
                    self.setMembers(for: conversationController.conversation)
                case _ as MemberUpdatedEvent:
                    break
                default:
                    break
                }
            }).store(in: &self.conversationCancellables)
    }
}
