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

    let stackedView = StackedPersonView()
    let button = ThemeButton()
    let topicLabel = ThemeLabel(font: .small)
    let jibImageView = UIImageView(image: UIImage(named: "jiblogo"))
    let roomsButton = RoomNavigationButton()
    
    private var state: ConversationUIState = .read
        
    override func initializeViews() {
        super.initializeViews()

        self.view.clipsToBounds = false
        
        self.view.addSubview(self.stackedView)
        self.stackedView.max = 7
        
        self.view.addSubview(self.jibImageView)
        self.jibImageView.contentMode = .scaleToFill
        self.jibImageView.isUserInteractionEnabled = true 
        
        self.view.addSubview(self.topicLabel)
        self.topicLabel.textAlignment = .center
        
        self.view.addSubview(self.button)
        
        self.view.addSubview(self.roomsButton)
        self.roomsButton.configure(for: .inner)
        
        ConversationsManager.shared.$activeConversation
            .removeDuplicates()
            .mainSink { [unowned self] conversation in
                guard let convo = conversation else {
                    self.topicLabel.text = nil
                    self.topicLabel.isVisible = false
                    self.stackedView.isVisible = false
                    return
                }
                
                self.startLoadDataTask(with: conversation)
                
                self.setTopic(for: convo)
                self.stackedView.isVisible = true
                self.topicLabel.isVisible = true
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
        self.topicLabel.pin(.bottom)
        
        self.stackedView.centerOnX()
        self.stackedView.match(.bottom, to: .top, of: self.topicLabel, offset: .negative(.short))
        
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
            self?.stackedView.configure(with: members)
            self?.view.setNeedsLayout()
        }
    }

    /// The subscriptions for the current conversation.
    private var conversationCancellables = Set<AnyCancellable>()

    private func subscribeToUpdates(for conversationController: ConversationController) {
        // Clear out previous subscriptions.
        self.conversationCancellables.removeAll()
        
        conversationController
            .channelChangePublisher
            .mainSink { [unowned self] _ in
                guard let conversation = self.conversationController?.conversation else { return }
                self.setTopic(for: conversation)
            }.store(in: &self.cancellables)

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
