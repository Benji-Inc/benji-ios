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
                                   ConversationsDataSource> {
    
    private(set) var conversationListController: ConversationListController?
    
    init() {
        super.init(with: ConversationsCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource.didSelectSegmentIndex = { [unowned self] index in
            switch index {
            case .recents:
                self.startLoadRecentTask()
            case .all:
                self.startLoadAllTask()
            case .unread:
                self.startLoadingUnreadConversations()
            }
        }
        
        self.loadInitialData()
        
        self.collectionView.allowsMultipleSelection = false 
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
                                     sort: [Sorting(key: .lastMessageAt, isAscending: false)],
                                     pageSize: 5,
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
    
    private func startLoadingUnreadConversations() {
        self.loadConversationsTask?.cancel()
        
        self.loadConversationsTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            try? await NoticeStore.shared.initializeIfNeeded()
            
            if let unreadNotice = NoticeStore.shared.notices.first(where: { system in
                return system.notice?.type == .unreadMessages
            }), let models: [UnreadMessagesModel] = unreadNotice.notice?.unreadConversations.compactMap({ dict in
                if let conversation = JibberChatClient.shared.conversation(for: dict.key), conversation.totalUnread > 0 {
                    return UnreadMessagesModel(conversationId: dict.key, messageIds: dict.value)
                }
                return nil
            }) {
                
                if models.isEmpty {
                    var snapshot = self.dataSource.snapshot()
                    snapshot.setItems([.empty], in: .conversations)
                    await self.dataSource.apply(snapshot)
                    return
                }
                                
                let cids = models.compactMap { model in
                    return try? ChannelId(cid: model.conversationId)
                }
                
                let filter = Filter<ChannelListFilterScope>.containsAtLeastThese(conversationIds: cids)
                let query = ChannelListQuery(filter: filter,
                                             sort: [Sorting(key: .lastMessageAt, isAscending: false)])
                
                await self.loadUnreadConversations(with: query, models: models)
            } else {
                var snapshot = self.dataSource.snapshot()
                snapshot.setItems([.empty], in: .conversations)
                await self.dataSource.apply(snapshot)
            }
        }.add(to: self.autocancelTaskPool)
    }
    
    private func startLoadRecentTask() {
        self.loadConversationsTask?.cancel()
        
        self.loadConversationsTask = Task { [weak self] in
            guard let user = User.current() else { return }
            
            let userIds: [String] = [user.objectId!]
            
            let filter = Filter<ChannelListFilterScope>.containsAtLeastThese(userIds: userIds)
            let query = ChannelListQuery(filter: filter,
                                         sort: [Sorting(key: .lastMessageAt, isAscending: false)],
                                         pageSize: 5,
                                         messagesLimit: 1)
            
            await self?.loadConversations(with: query)
        }.add(to: self.autocancelTaskPool)
    }
    
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
    private func loadUnreadConversations(with query: ChannelListQuery, models: [UnreadMessagesModel]) async {
        self.conversationListController = ConversationController.controller(query: query)
        
        try? await self.conversationListController?.synchronize()
        
        guard !Task.isCancelled else { return }
                
        let items = models.map { model in
            return ConversationsDataSource.ItemType.unreadMessages(model)
        }
        var snapshot = self.dataSource.snapshot()
        snapshot.setItems(items, in: .conversations)
        
        await self.dataSource.apply(snapshot)
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
    }
}
