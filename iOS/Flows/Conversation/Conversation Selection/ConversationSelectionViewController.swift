//
//  ConversationSelectionViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ConversationSelectionViewController: DiffableCollectionViewController<ConversationSelectionDataSource.SectionType,
                                           ConversationSelectionDataSource.ItemType,
                                           ConversationSelectionDataSource> {
    
    private let topGradientView = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor,
                                                                 ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                          startPoint: .topCenter,
                                                          endPoint: .bottomCenter)
    
    private let titleLabel = ThemeLabel(font: .mediumBold)
    
    private(set) var conversationListController: ConversationListController?
    
    init() {
        super.init(with: ConversationSelectionCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.allowsMultipleSelection = false
        self.loadInitialData()
        
        self.view.addSubview(self.topGradientView)
        self.view.addSubview(self.titleLabel)
        self.titleLabel.setText("Choose")
        self.titleLabel.textAlignment = .center
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.topGradientView.expandToSuperviewWidth()
        self.topGradientView.height = 80
        self.topGradientView.pin(.top)
        
        self.titleLabel.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.titleLabel.pinToSafeAreaTop()
        self.titleLabel.centerOnX()
    }
    
    override func getAllSections() -> [ConversationSelectionDataSource.SectionType] {
        return ConversationSelectionDataSource.SectionType.allCases
    }
    
    override func retrieveDataForSnapshot() async -> [ConversationSelectionDataSource.SectionType : [ConversationSelectionDataSource.ItemType]] {
       
        var data: [ConversationSelectionDataSource.SectionType: [ConversationSelectionDataSource.ItemType]] = [:]
        
        guard let user = User.current() else { return data }
        
        let userIds: [String] = [user.objectId!]
                        
        let filter = Filter<ChannelListFilterScope>.containsAtLeastThese(userIds: userIds)
        let query = ChannelListQuery(filter: filter,
                                     sort: [Sorting(key: .createdAt, isAscending: false)],
                                     pageSize: .channelsPageSize,
                                     messagesLimit: 1)
        
        self.conversationListController = ConversationController.controller(query: query)
        
        try? await self.conversationListController?.synchronize()
                
        let conversationIds: [String] = self.conversationListController?.conversations.filter({ conversation in
            return conversation.memberCount > 1 
        }).compactMap({ conversation in
            return conversation.id
        }) ?? []
        
        let items = conversationIds.map { conversationId in
            return ConversationSelectionDataSource.ItemType.conversation(conversationId)
        }
        
        data[.conversations] = items
        
        return data
    }
}
