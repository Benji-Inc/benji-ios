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
    
    typealias ResultType = Void
    
    var onDidComplete: ((Result<Void, Error>) -> Void)?
    
    let button = ThemeButton()
    
    var welcomeCollectionView: WelcomeCollectionView {
        return self.collectionView as! WelcomeCollectionView
    }
    
    private(set) var conversationController: ConversationController?
    
    static let cid = ChannelId(type: .custom("onboarding"), id: "BD-DA81E593-B9A6-4A03-B822-52D0C5A66B7C")
    static let benjiId = "xGA45bkNmv"
    
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
        
        self.view.addSubview(self.button)
        self.button.set(style: .normal(color: .B2, text: "Join the Waitlist"))
        self.button.didSelect { [unowned self] in
            self.onDidComplete?(.success(()))
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.button.setSize(with: self.view.width)
        self.button.pinToSafeAreaBottom()
        self.button.centerOnX()
        
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.pin(.top, offset: .custom(self.view.height * 0.3))
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

            let conversationController
            = ChatClient.shared.channelController(for: WelcomeViewController.cid,
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
                if message.authorId == WelcomeViewController.benjiId {
                    benjiMessages.append(MessageSequenceItem.message(cid: WelcomeViewController.cid, messageID: message.id))
                } else {
                    otherMessages.append(MessageSequenceItem.message(cid: WelcomeViewController.cid, messageID: message.id))
                }
            })
            
            data[.topMessages] = benjiMessages
            data[.bottomMessages] = otherMessages
        } catch {
            logDebug(error.code.description)
        }
        
        return data
    }
}
