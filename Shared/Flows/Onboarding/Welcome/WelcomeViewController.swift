//
//  newWelcomeViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Parse

class WelcomeViewController: DiffableCollectionViewController<MessageSequenceSection,
                             MessageSequenceItem,
                             MessageSequenceCollectionViewDataSource>,
                             Sizeable,
                             Completable {
    
    typealias ResultType = SelectionType
    
    enum SelectionType {
        case waitlist
        case rsvp
    }
    
    var didLoadConversation: ((Conversation) -> Void)? 
    var onDidComplete: ((Result<SelectionType, Error>) -> Void)?
    
    let waitlistButton = ThemeButton()
    let rsvpButton = ThemeButton()
    
    var welcomeCollectionView: WelcomeCollectionView {
        return self.collectionView as! WelcomeCollectionView
    }
    
    private(set) var conversationController: ConversationController?
    
    init() {
        super.init(with: WelcomeCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()
        
        self.welcomeCollectionView.timeMachineLayout.dataSource = self.dataSource
        
        self.view.addSubview(self.collectionView)
        self.collectionView.clipsToBounds = false
        
        self.view.addSubview(self.waitlistButton)
        self.waitlistButton.set(style: .normal(color: .B2, text: "Begin"))
        self.waitlistButton.didSelect { [unowned self] in
            self.onDidComplete?(.success((.waitlist)))
        }
        
        self.view.addSubview(self.rsvpButton)
        self.rsvpButton.set(style: .normal(color: .B3, text: "RSVP"))
        self.rsvpButton.didSelect { [unowned self] in
            self.onDidComplete?(.success((.rsvp)))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadInitialData()
    }
    
    override func collectionViewDataWasLoaded() {
        super.collectionViewDataWasLoaded()
        
        if let convo = self.conversationController?.conversation {
            self.didLoadConversation?(convo)
        }
        
        Task {
            await Task.sleep(seconds: 0.1)
            self.welcomeCollectionView.timeMachineLayout.prepare()
            let maxOffset = self.welcomeCollectionView.timeMachineLayout.maxZPosition
            self.collectionView.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: true)
            self.welcomeCollectionView.timeMachineLayout.invalidateLayout()
        }.add(to: self.taskPool)
    }
    
    override func getAnimationCycle(with snapshot: NSDiffableDataSourceSnapshot<MessageSequenceSection, MessageSequenceItem>) -> AnimationCycle? {
        return AnimationCycle(inFromPosition: .inward,
                              outToPosition: .inward,
                              shouldConcatenate: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.rsvpButton.setSize(with: self.view.width)
        self.rsvpButton.pinToSafeAreaBottom()
        self.rsvpButton.centerOnX()
        
        self.waitlistButton.setSize(with: self.view.width)
        self.waitlistButton.match(.bottom, to: .top, of: self.rsvpButton, offset: .negative(.standard))
        self.waitlistButton.centerOnX()
        
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.pin(.top, offset: .custom(self.view.height * 0.25))
        self.collectionView.width = Theme.getPaddedWidth(with: self.view.width)
        self.collectionView.height = self.view.height - self.collectionView.top
        self.collectionView.centerOnX()
    }
    
    // MARK: Data Loading

    override func getAllSections() -> [MessageSequenceSection] {
        return [.topMessages, .bottomMessages]
    }

    override func retrieveDataForSnapshot() async -> [MessageSequenceSection : [MessageSequenceItem]] {
        var data: [MessageSequenceSection: [MessageSequenceItem]] = [:]
        
        do {
            if !ChatClient.isConnected {
                try await ChatClient.connectAnonymousUser()
            }
            
            guard let conversationId = PFConfig.current().welcomeConversationCID else { return data }
            
            let cid = ChannelId(type: .custom("onboarding"), id: conversationId)
            let conversationController
            = ChatClient.shared.channelController(for: cid,
                                                     messageOrdering: .topToBottom)
            self.conversationController = conversationController

            // Ensure that we've synchronized the conversation controller with the backend.
            if conversationController.channel.isNil {
                try await conversationController.synchronize()
            } else if let conversation = conversationController.channel, conversation.messages.isEmpty {
                try await conversationController.synchronize()
            }
            
            try await conversationController.loadPreviousMessages()

            // Put Benji's messages at the top, and all other messages below.
            var benjiMessages: [MessageSequenceItem] = []
            var otherMessages: [MessageSequenceItem] = []
            
            conversationController.messages.forEach({ message in
                if message.authorId == PFConfig.current().adminUserId {
                    benjiMessages.append(MessageSequenceItem.message(cid: cid,
                                                                     messageID: message.id,
                                                                     showDetail: false))
                } else {
                    otherMessages.append(MessageSequenceItem.message(cid: cid, messageID:
                                                                        message.id,
                                                                     showDetail: false))
                }
            })
            
            data[.topMessages] = benjiMessages.reversed()
            data[.bottomMessages] = otherMessages.reversed()
        } catch {
            logDebug(error.code.description)
        }
        
        return data
    }
}
