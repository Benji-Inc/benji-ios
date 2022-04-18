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
    
    let headerView = RoomHeaderView()
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
        let top = UIWindow.topWindow()?.safeAreaInsets.top ?? 0 + 46
        cv.contentInset = UIEdgeInsets(top: top,
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
        
        self.view.set(backgroundColor: .B0)
        
        self.view.addSubview(self.bottomGradientView)
        self.view.addSubview(self.topGradientView)
        self.view.addSubview(self.headerView)
        
        self.collectionView.allowsMultipleSelection = false
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
    }
    
    override func collectionViewDataWasLoaded() {
        super.collectionViewDataWasLoaded()
        
        self.startLoadRecentTask()
        self.subscribeToUpdates()
    }
    
    private func subscribeToUpdates() {
        
        PeopleStore.shared.$personDeleted.mainSink { [unowned self] _ in
            Task {
                await self.reloadPeople()
            }
        }.store(in: &self.cancellables)
        
        PeopleStore.shared.$personAdded.mainSink { [unowned self] _ in
            Task {
                await self.reloadPeople()
            }
        }.store(in: &self.cancellables)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.headerView.height = 46
        self.headerView.expandToSuperviewWidth()
        self.headerView.pinToSafeArea(.top, offset: .xtraLong)
        
        self.topGradientView.expandToSuperviewWidth()
        self.topGradientView.height = self.headerView.bottom
        self.topGradientView.pin(.top)
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
    }
    
    override func getAllSections() -> [RoomSectionType] {
        return RoomCollectionViewDataSource.SectionType.allCases
    }
    
    override func retrieveDataForSnapshot() async -> [RoomSectionType : [RoomItemType]] {
        var data: [RoomSectionType: [RoomItemType]] = [:]
        
        try? await NoticeStore.shared.initializeIfNeeded()
        let notices = await NoticeStore.shared.getAllNotices().filter({ notice in
            return notice.type != .unreadMessages
        })
        
        data[.notices] = notices.compactMap({ notice in
            return .notice(notice)
        })
        
        data[.members] = PeopleStore.shared.people.filter({ type in
            return !type.isCurrentUser
        }).sorted(by: { lhs, rhs in
            guard let lhsUpdated = lhs.updatedAt,
                  let rhsUpdated = rhs.updatedAt else { return false }
            return lhsUpdated > rhsUpdated
        }).compactMap({ type in
            return .memberId(type.personId)
        })
        
        let addItems: [RoomItemType] = PeopleStore.shared.unclaimedReservations.keys.compactMap { reservationId in
            return .add(reservationId)
        }
        
        data[.members]?.append(contentsOf: addItems)
        
        return data
    }
    
    @MainActor
    func reloadNotices() async {
        
        try? await NoticeStore.shared.initializeIfNeeded()
        let notices = await NoticeStore.shared.getAllNotices().filter({ notice in
            return notice.type != .unreadMessages
        })
        
        var items: [RoomItemType] = notices
            .compactMap({ notice in
            return .notice(notice)
        })
        
        let addItems: [RoomItemType] = PeopleStore.shared.unclaimedReservations.keys.compactMap { reservationId in
            return .add(reservationId)
        }
        
        items.append(contentsOf: addItems)
        
        var snapshot = self.dataSource.snapshot()
        snapshot.setItems(items, in: .notices)
        
        await self.dataSource.apply(snapshot)
    }
    
    @MainActor
    func reloadPeople() async {
        
        guard !Task.isCancelled else { return }
        
        let items: [RoomItemType] = PeopleStore.shared.people.filter({ type in
            return !type.isCurrentUser
        }).sorted(by: { lhs, rhs in
            guard let lhsUpdated = lhs.updatedAt,
                  let rhsUpdated = rhs.updatedAt else { return false }
            return lhsUpdated > rhsUpdated
        }).compactMap({ type in
            return .memberId(type.personId)
        })
        
        var snapshot = self.dataSource.snapshot()
        snapshot.setItems(items, in: .members)
        
        await self.dataSource.apply(snapshot)
    }
    
    // MARK: - Conversation Loading
    
    /// The currently running task that is loading conversations.
    private var loadConversationsTask: Task<Void, Never>?
    
    private func startLoadingUnreadConversations() {
        self.loadConversationsTask?.cancel()
        
        self.loadConversationsTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            try? await NoticeStore.shared.initializeIfNeeded()
            
            if let unreadNotice = await NoticeStore.shared.getAllNotices().first(where: { system in
                return system.notice?.type == .unreadMessages
            }), let models: [UnreadMessagesModel] = unreadNotice.notice?.unreadConversations.compactMap({ dict in
                if let cid = try? ConversationId(cid: dict.key) {
                    return UnreadMessagesModel(cid: cid, messageIds: dict.value)
                }
                return nil
            }) {
                
                let conversationIds = models.compactMap { model in
                    return model.cid
                }
                
                let filter = Filter<ChannelListFilterScope>.containsAtLeastThese(conversationIds: conversationIds)
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
            
            var userIds: [String] = []
            userIds.append(user.objectId!)
            
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
        self.conversationListController
        = ChatClient.shared.channelListController(query: query)
        
        try? await self.conversationListController?.synchronize()
        
        guard !Task.isCancelled else { return }
                
        let items = models.map { model in
            return RoomCollectionViewDataSource.ItemType.unreadMessages(model)
        }
        var snapshot = self.dataSource.snapshot()
        snapshot.setItems(items, in: .conversations)
        
        await self.dataSource.apply(snapshot)
    }
    
    @MainActor
    private func loadConversations(with query: ChannelListQuery) async {
        self.conversationListController
        = ChatClient.shared.channelListController(query: query)
        
        try? await self.conversationListController?.synchronize()
        
        guard !Task.isCancelled else { return }
        
        let conversations: [Conversation] = self.conversationListController?.conversations ?? []
        
        let items = conversations.filter({ conversation in
            let messages = conversation.messages.filter { message in
                return !message.isDeleted
            }
            return messages.count > 0
        }).map { convo in
            return RoomCollectionViewDataSource.ItemType.conversation(convo.cid)
        }
        var snapshot = self.dataSource.snapshot()
        snapshot.setItems(items, in: .conversations)
        
        await self.dataSource.apply(snapshot)
    }
}

extension RoomViewController: TransitionableViewController {
    var receivingPresentationType: TransitionType {
        return .fade
    }
}
