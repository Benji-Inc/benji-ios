//
//  CircleViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class RoomViewController: DiffableCollectionViewController<RoomSectionType,
                          RoomItemType,
                          RoomCollectionViewDataSource> {
    
    private let topGradientView = GradientView(with: [ThemeColor.B0.color.cgColor,
                                                      ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                               startPoint: .topCenter,
                                               endPoint: .bottomCenter)
    
    private let bottomGradientView = GradientView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .bottomCenter,
                                                  endPoint: .topCenter)
    
    private(set) var conversationListController: ConversationListController?
    
    init() {
        let cv = CollectionView(layout: RoomCollectionViewLayout())
        cv.contentInset = UIEdgeInsets(top: Theme.ContentOffset.xtraLong.value,
                                       left: 0,
                                       bottom: 100,
                                       right: 0)
        super.init(with: cv)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        
        self.view.set(backgroundColor: .B0)
        
        self.view.addSubview(self.bottomGradientView)
        self.view.addSubview(self.topGradientView)
        
        self.collectionView.allowsMultipleSelection = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadInitialData()
    }
    
    override func collectionViewDataWasLoaded() {
        super.collectionViewDataWasLoaded()
        
        self.startLoadRecentTask()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.topGradientView.expandToSuperviewWidth()
        self.topGradientView.pin(.top)
        self.topGradientView.height = Theme.ContentOffset.xtraLong.value.doubled
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
    }
    
    override func getAllSections() -> [RoomSectionType] {
        return RoomCollectionViewDataSource.SectionType.allCases
    }
    
    override func retrieveDataForSnapshot() async -> [RoomSectionType : [RoomItemType]] {
        var data: [RoomSectionType: [RoomItemType]] = [:]
        data[.members] = PeopleStore.shared.people.filter({ type in
            return !type.isCurrentUser
        }).compactMap({ type in
            return .memberId(type.personId)
        })
        return data
    }
    
    // MARK: - Conversation Loading
    
    /// The currently running task that is loading conversations.
    private var loadConversationsTask: Task<Void, Never>?
    
    private func startLoadArchiveTask() {
        self.loadConversationsTask?.cancel()
        
        self.loadConversationsTask = Task { [weak self] in
            guard let user = User.current() else { return }
            
            var userIds: [String] = []
            userIds.append(user.objectId!)
            
            let filter = Filter<ChannelListFilterScope>.containsAtLeastThese(userIds: userIds)
            let query = ChannelListQuery(filter: .and([.equal("hidden", to: true), filter]),
                                         sort: [Sorting(key: .createdAt, isAscending: true)],
                                         pageSize: .channelsPageSize,
                                         messagesLimit: 1)
            
            await self?.loadConversations(with: query)
        }.add(to: self.autocancelTaskPool)
    }
    
    private func startLoadRecentTask() {
        self.loadConversationsTask?.cancel()
        
        self.loadConversationsTask = Task { [weak self] in
            guard let user = User.current() else { return }
            
            var userIds: [String] = []
            userIds.append(user.objectId!)
            
            let filter = Filter<ChannelListFilterScope>.containsAtLeastThese(userIds: userIds)
            let query = ChannelListQuery(filter: filter,
                                         sort: [Sorting(key: .updatedAt, isAscending: true)],
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
                                         sort: [Sorting(key: .createdAt, isAscending: true)],
                                         pageSize: .channelsPageSize,
                                         messagesLimit: 1)
            
            await self?.loadConversations(with: query)
        }.add(to: self.autocancelTaskPool)
    }
    
    @MainActor
    private func loadConversations(with query: ChannelListQuery) async {
        self.conversationListController
        = ChatClient.shared.channelListController(query: query)
        
        try? await self.conversationListController?.synchronize()
        
        guard !Task.isCancelled else { return }
        
        let conversations: [Conversation] = self.conversationListController?.conversations ?? []
        
        let items = conversations.filter({ conversation in
            return conversation.messages.count > 0
        }).map { convo in
            return RoomCollectionViewDataSource.ItemType.conversation(convo.cid)
        }
        var snapshot = self.dataSource.snapshot()
        snapshot.setItems(items, in: .conversations)
        
        await self.dataSource.apply(snapshot)
    }
}
