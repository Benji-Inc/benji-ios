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
        
        self.collectionView.clipsToBounds = false
        
        self.view.addSubview(self.waitlistButton)
        self.waitlistButton.set(style: .custom(color: .D1, textColor: .white, text: "Begin"))
        self.waitlistButton.didSelect { [unowned self] in
            self.onDidComplete?(.success((.waitlist)))
        }
        
        if !isRelease {
            self.view.addSubview(self.rsvpButton)
            self.rsvpButton.set(style: .custom(color: .B5, textColor: .T4, text: "RSVP"))
            self.rsvpButton.didSelect { [unowned self] in
                self.onDidComplete?(.success((.rsvp)))
            }
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
    }
    
    override func getAnimationCycle(with snapshot: NSDiffableDataSourceSnapshot<MessageSequenceSection, MessageSequenceItem>) -> AnimationCycle? {
        let count = (snapshot.numberOfItems(inSection: .topMessages) + snapshot.numberOfItems(inSection: .bottomMessages)) - 1
        let maxOffset = CGFloat(count) * self.welcomeCollectionView.timeMachineLayout.itemHeight
        
        return AnimationCycle(inFromPosition: nil,
                              outToPosition: nil,
                              shouldConcatenate: false,
                              scrollToOffset: CGPoint(x: 0, y: maxOffset))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isRelease {
            self.rsvpButton.setSize(with: self.view.width)
            self.rsvpButton.pinToSafeAreaBottom()
            self.rsvpButton.centerOnX()
        }
        
        self.waitlistButton.setSize(with: self.view.width)
        if !isRelease {
            self.waitlistButton.match(.bottom, to: .top, of: self.rsvpButton, offset: .negative(.standard))
        } else {
            self.waitlistButton.pinToSafeAreaBottom()
        }
        
        self.waitlistButton.centerOnX()
    }
    
    override func layoutCollectionView(_ collectionView: UICollectionView) {
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

            let allMessages = conversationController.messages.filter { message in
                return !message.isDeleted
            }

            allMessages.forEach({ message in
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
            logError(error)
        }
        
        return data
    }
}
