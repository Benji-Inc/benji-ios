//
//  newWelcomeViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class newWelcomeViewController: DiffableCollectionViewController<MessageSequenceSection,
                                MessageSequenceItem,
                                MessageSequenceCollectionViewDataSource>,
                                Sizeable, Completable {
    
    typealias ResultType = Void
    
    var onDidComplete: ((Result<Void, Error>) -> Void)?
    
    let button = ThemeButton()
    
    var welcomeCollectionView: WelcomeCollectionView {
        return self.collectionView as! WelcomeCollectionView
    }
    
    private(set) var conversationController: ConversationController?
    
    static let cid = ChannelId(type: .messaging, id: "BD-8A8AB720-E8AD-45BC-9A55-C78CB9154BD5")
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
        
        self.view.addSubview(self.button)
        self.button.set(style: .normal(color: .white, text: "Join the Waitlist"))
        self.button.didSelect { [unowned self] in
            
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.button.setSize(with: self.view.width)
        self.button.pinToSafeAreaBottom()
        self.button.centerOnX()
        
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.pinToSafeArea(.top, offset: .noOffset)
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
            
            if let current = User.current(), !ChatClient.isConnected {
                try await ChatClient.initialize(for: current)
                self.conversationController = ChatClient.shared.channelController(for: newWelcomeViewController.cid, messageOrdering: .topToBottom)
            }
            
            try await self.conversationController?.loadNextMessages()
            
            var benjiMessages: [MessageSequenceItem] = []
            var otherMessages: [MessageSequenceItem] = []
            
            self.conversationController?.messages.forEach({ message in
                if message.authorId == newWelcomeViewController.benjiId {
                    benjiMessages.append(MessageSequenceItem.message(cid: newWelcomeViewController.cid, messageID: message.id))
                } else {
                    otherMessages.append(MessageSequenceItem.message(cid: newWelcomeViewController.cid, messageID: message.id))
                }
            })
            
            data[.topMessages] = benjiMessages
            data[.bottomMessages] = otherMessages
        } catch {
            logError(error)
        }
        
        return data
    }
}
