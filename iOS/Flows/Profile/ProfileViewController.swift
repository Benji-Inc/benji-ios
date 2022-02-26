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
        //super.init(with: WalletCollectionView())
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        Task {
            if let user = self.avatar as? User,
               let updated = try? await user.retrieveDataIfNeeded() {
                self.avatar = updated
                self.header.configure(with: updated)
                self.loadInitialData()
            } else if let userId = self.avatar.userObjectId,
                        let user = try? await User.getObject(with: userId),
                      let updated = try? await user.retrieveDataIfNeeded() {
                self.avatar = updated
                self.header.configure(with: updated)
                self.loadInitialData()
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
        let segmentWidth = totalWidth * 0.3333
        self.segmentControl.sizeToFit()
        self.segmentControl.setWidth(segmentWidth, forSegmentAt: 0)
        self.segmentControl.setWidth(segmentWidth, forSegmentAt: 1)
        self.segmentControl.setWidth(segmentWidth, forSegmentAt: 2)

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
        self.collectionView.match(.top, to: .bottom, of: self.contextCuesVC.view, offset: .custom(64))
        self.collectionView.height = self.view.height - self.contextCuesVC.view.bottom - 64
        self.collectionView.centerOnX()
    }
    
    override func getAllSections() -> [UserConversationsDataSource.SectionType] {
        return UserConversationsDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [UserConversationsDataSource.SectionType : [UserConversationsDataSource.ItemType]] {

        var data: [UserConversationsDataSource.SectionType : [UserConversationsDataSource.ItemType]] = [:]

        let filter = Filter<ChannelListFilterScope>.containMembers(userIds: [User.current()!.objectId!])

        let query = ChannelListQuery(filter: filter,
                                     sort: [Sorting(key: .createdAt, isAscending: true)],
                                     pageSize: .channelsPageSize,
                                     messagesLimit: .messagesPageSize)
        self.conversationListController
        = ChatClient.shared.channelListController(query: query)

        try? await self.conversationListController?.synchronize()
        try? await self.conversationListController?.loadNextConversations(limit: .channelsPageSize)

        let conversations: [Conversation] = self.conversationListController?.conversations ?? []

        data[.conversations] = conversations.map({ conversation in
            return .conversation(conversation.cid)
        })

        return data
    }
}
