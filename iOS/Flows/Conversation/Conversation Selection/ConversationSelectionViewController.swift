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
                
        let conversationIds: [String] = self.conversationListController?.conversations.compactMap({ conversation in
            return conversation.id
        }) ?? []
        
        let items = conversationIds.map { conversationId in
            return ConversationSelectionDataSource.ItemType.conversation(conversationId)
        }
        
        data[.conversations] = items
        
        return data
    }
}
