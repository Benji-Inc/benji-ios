//
//  ConversationsViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ConversationsViewController: DiffableCollectionViewController<ConversationsDataSource.SectionType,
                                   ConversationsDataSource.ItemType,
                                   ConversationsDataSource>, HomeContentType {
    
    var contentTitle: String {
        return "Conversations"
    }
    
    private(set) var conversationListController: ConversationListController?
    
    private lazy var refreshControl: UIRefreshControl = {
        let action = UIAction { [unowned self] _ in
            self.startLoadAllTask()
        }
        let control = UIRefreshControl(frame: .zero, primaryAction: action)
        control.tintColor = ThemeColor.white.color
        return control
    }()
    
    init() {
        super.init(with: ConversationsCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadInitialData()
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.refreshControl = self.refreshControl
    }
    
    override func getAllSections() -> [ConversationsDataSource.SectionType] {
        return ConversationsDataSource.SectionType.allCases
    }
    
    override func retrieveDataForSnapshot() async -> [ConversationsDataSource.SectionType : [ConversationsDataSource.ItemType]] {
        var data: [ConversationsDataSource.SectionType: [ConversationsDataSource.ItemType]] = [:]
        
        guard let user = User.current() else { return data }
        
        let userIds: [String] = [user.objectId!]
                        
        let filter = Filter<ChannelListFilterScope>.containsAtLeastThese(userIds: userIds)
        let query = ChannelListQuery(filter: filter,
                                     sort: [Sorting(key: .createdAt, isAscending: false)],
                                     pageSize: .channelsPageSize,
                                     messagesLimit: 1)
        
        self.conversationListController = ConversationController.controller(query: query)
        
        try? await self.conversationListController?.synchronize()
                
        let conversations: [Conversation] = self.conversationListController?.conversations ?? []
        
        let items = conversations.filter({ conversation in
            let messages = conversation.messages.filter { message in
                return !message.isDeleted
            }
            return messages.count > 0
        }).map { convo in
            return ConversationsDataSource.ItemType.conversation(convo.cid.description)
        }
        
        data[.conversations] = items
        
        return data
    }
    
    // MARK: - Conversation Loading
    
    /// The currently running task that is loading conversations.
    private var loadConversationsTask: Task<Void, Never>?
    
    private func startLoadAllTask() {
        self.loadConversationsTask?.cancel()
        
        self.loadConversationsTask = Task { [weak self] in
            guard let user = User.current() else { return }
            
            var userIds: [String] = []
            userIds.append(user.objectId!)
            
            let filter = Filter<ChannelListFilterScope>.containsAtLeastThese(userIds: userIds)
            let query = ChannelListQuery(filter: filter,
                                         sort: [Sorting(key: .createdAt, isAscending: false)],
                                         pageSize: .channelsPageSize,
                                         messagesLimit: 1)
            
            await self?.loadConversations(with: query)
        }.add(to: self.autocancelTaskPool)
    }
    
    @MainActor
    private func loadConversations(with query: ChannelListQuery) async {
        self.conversationListController = ConversationController.controller(query: query)
        
        try? await self.conversationListController?.synchronize()
        
        guard !Task.isCancelled else { return }
        
        let conversations: [Conversation] = self.conversationListController?.conversations ?? []
        
        let items = conversations.filter({ conversation in
            let messages = conversation.messages.filter { message in
                return !message.isDeleted
            }
            return messages.count > 0
        }).map { convo in
            return ConversationsDataSource.ItemType.conversation(convo.cid.description)
        }
        var snapshot = self.dataSource.snapshot()
        snapshot.setItems(items, in: .conversations)
        
        await self.dataSource.apply(snapshot)
        
        if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }
    }
}
