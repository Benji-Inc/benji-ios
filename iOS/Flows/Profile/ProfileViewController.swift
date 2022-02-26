//
//  UserProfileViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ProfileViewController: DiffableCollectionViewController<UserConversationsDataSource.SectionType,
                             UserConversationsDataSource.ItemType,
                             UserConversationsDataSource> {
    
    private var avatar: Avatar
    
    lazy var header = ProfileHeaderView()
    private lazy var contextCuesVC = ContextCuesViewController()
    
    private let segmentGradientView = GradientView(with: [ThemeColor.walletBackground.color.cgColor,
                                                         ThemeColor.walletBackground.color.cgColor,
                                                         ThemeColor.walletBackground.color.cgColor,
                                                         ThemeColor.walletBackground.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .topCenter,
                                                  endPoint: .bottomCenter)
    private let backgroundView = BaseView()
    lazy var segmentControl = ConversationsSegmentControl()
    
    private(set) var conversationListController: ConversationListController?
    
    private let bottomGradientView = GradientView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .bottomCenter,
                                                  endPoint: .topCenter)
        
    init(with avatar: Avatar) {
        self.avatar = avatar
        super.init(with: UserConversationsCollectionView())
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
                
        self.view.addSubview(self.header)
        self.addChild(viewController: self.contextCuesVC, toView: self.view)
        
        self.view.addSubview(self.bottomGradientView)
        
        self.backgroundView.set(backgroundColor: .walletBackground)
        self.backgroundView.layer.cornerRadius = Theme.cornerRadius
        self.backgroundView.layer.masksToBounds = true
        self.backgroundView.clipsToBounds = true
        
        self.segmentGradientView.layer.cornerRadius = Theme.cornerRadius
        self.segmentGradientView.layer.masksToBounds = true
        self.segmentGradientView.clipsToBounds = true
        
        self.view.insertSubview(self.backgroundView, belowSubview: self.collectionView)
        self.view.insertSubview(self.segmentControl, aboveSubview: self.collectionView)
        self.view.insertSubview(self.segmentGradientView, belowSubview: self.segmentControl)
        
        self.segmentControl.didSelectSegmentIndex = { [unowned self] index in
            switch index {
            case .recents:
                self.loadRecents()
            case .all:
                self.loadAll()
            case .archive:
                self.loadArchive()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.allowsMultipleSelection = false 
                
        Task {
            if let user = self.avatar as? User,
               let updated = try? await user.retrieveDataIfNeeded() {
                self.avatar = updated
                self.header.configure(with: updated)
                self.loadInitialData()
                if !user.isCurrentUser {
                    self.segmentControl.removeSegment(at: 0, animated: false)
                    self.segmentControl.selectedSegmentIndex = 0
                } else {
                    self.segmentControl.selectedSegmentIndex = 1
                }
                self.loadRecents()
                self.view.layoutNow()
            } else if let userId = self.avatar.userObjectId,
                        let user = try? await User.getObject(with: userId),
                      let updated = try? await user.retrieveDataIfNeeded() {
                self.avatar = updated
                self.header.configure(with: updated)
                self.loadInitialData()
                if !user.isCurrentUser {
                    self.segmentControl.removeSegment(at: 0, animated: false)
                    self.segmentControl.selectedSegmentIndex = 0
                } else {
                    self.segmentControl.selectedSegmentIndex = 1
                }
                
                self.loadRecents()
                self.view.layoutNow()
            }
        }.add(to: self.autocancelTaskPool)
    }
    
    override func viewDidLayoutSubviews() {
        
        self.header.expandToSuperviewWidth()
        self.header.height = 220
        self.header.pinToSafeAreaTop()
        
        super.viewDidLayoutSubviews()
        
        self.contextCuesVC.view.expandToSuperviewWidth()
        self.contextCuesVC.view.height = 40
        self.contextCuesVC.view.match(.top, to: .bottom, of: self.header)
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
        
        let padding = Theme.ContentOffset.xtraLong.value
        let totalWidth = self.collectionView.width - padding.doubled
        let multiplier = self.segmentControl.numberOfSegments < 3 ? 0.5 : 0.333
        let segmentWidth = totalWidth * multiplier
        self.segmentControl.sizeToFit()
        
        for index in 0...self.segmentControl.numberOfSegments - 1 {
            self.segmentControl.setWidth(segmentWidth, forSegmentAt: index)
        }

        self.segmentControl.width = self.collectionView.width - padding.doubled
        self.segmentControl.centerOnX()
        self.segmentControl.match(.top, to: .top, of: self.collectionView, offset: .xtraLong)
        
        self.backgroundView.frame = self.collectionView.frame
        self.backgroundView.height = self.collectionView.height + 100
        
        self.segmentGradientView.width = self.collectionView.width
        self.segmentGradientView.top = self.collectionView.top
        self.segmentGradientView.height = padding.doubled + self.segmentControl.height
        self.segmentGradientView.centerOnX()
    }
    
    override func layoutCollectionView(_ collectionView: UICollectionView) {
        self.collectionView.width = self.view.width - Theme.ContentOffset.xtraLong.value.doubled
        self.collectionView.match(.top, to: .bottom, of: self.contextCuesVC.view, offset: .custom(34))
        self.collectionView.height = self.view.height - self.contextCuesVC.view.bottom - 34
        self.collectionView.centerOnX()
    }
    
    override func getAllSections() -> [UserConversationsDataSource.SectionType] {
        return UserConversationsDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [UserConversationsDataSource.SectionType : [UserConversationsDataSource.ItemType]] {
        return [:]
    }
    
    private func loadArchive() {
//        Task { [weak self] in
//            await self?.loadAchievements()
//        }.add(to: self.autocancelTaskPool)
    }
    
    private func loadRecents() {
        Task { [weak self] in
            guard let `self` = self, let user = self.avatar as? User else { return }
            var userIds: [String] = []
            
            if user.isCurrentUser {
                userIds.append(user.userObjectId!)
            } else {
                userIds = [User.current()!.objectId!, user.userObjectId!]
            }
            
            let filter = Filter<ChannelListFilterScope>.containMembers(userIds: userIds)
            let query = ChannelListQuery(filter: filter,
                                         sort: [Sorting(key: .updatedAt, isAscending: true)],
                                         pageSize: 5,
                                         messagesLimit: 1)
            self.conversationListController
            = ChatClient.shared.channelListController(query: query)

            try? await self.conversationListController?.synchronize()
            try? await self.conversationListController?.loadNextConversations(limit: .channelsPageSize)

            let conversations: [Conversation] = self.conversationListController?.conversations ?? []
            
            await self.load(conversations: conversations)
            
        }.add(to: self.autocancelTaskPool)
    }
    
    private func loadAll() {
//        Task { [weak self] in
//            guard let transactions = try? await Transaction.fetchAllConnectionsTransactions() else {
//                await self?.dataSource.deleteAllItems()
//                return
//            }
//
//            await self?.load(transactions: transactions)
//        }.add(to: self.autocancelTaskPool)
    }
    
    private func load(conversations: [Conversation]) async {
        let items = conversations.map { convo in
            return UserConversationsDataSource.ItemType.conversation(convo.cid)
        }
        var snapshot = self.dataSource.snapshot()
        snapshot.setItems([], in: .conversations)
        snapshot.setItems(items, in: .conversations)
        await self.dataSource.apply(snapshot)
    }
}
