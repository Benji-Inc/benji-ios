//
//  UserConversationsViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserConversationsViewController: DiffableCollectionViewController<UserConversationsDataSource.SectionType,
                                       UserConversationsDataSource.ItemType,
                                       UserConversationsDataSource> {
    
    init() {
        super.init(with: CollectionView(layout: UserConversationsCollectionViewLayout()))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getAllSections() -> [UserConversationsDataSource.SectionType] {
        return []
    }
    
    override func retrieveDataForSnapshot() async -> [UserConversationsDataSource.SectionType : [UserConversationsDataSource.ItemType]] {
        var data: [UserConversationsDataSource.SectionType : [UserConversationsDataSource.ItemType]] = [:]
        
        return data
    }
}
