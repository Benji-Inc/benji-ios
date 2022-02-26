//
//  UserConversationsDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserConversationsDataSource: CollectionViewDataSource<UserConversationsDataSource.SectionType, UserConversationsDataSource.ItemType> {
    
    enum SectionType: Int, CaseIterable {
        case conversations
    }
    
    enum ItemType: Hashable {
        case conversation(ConversationId)
        case fuckYou(Int)
    }
    
    let config = ManageableCellRegistration<ConversationCell>().provider
    let fuck = ManageableCellRegistration<FukCell>().provider
    
    override func dequeueCell(with collectionView: UICollectionView, indexPath: IndexPath, section: SectionType, item: ItemType) -> UICollectionViewCell? {
        
        switch item {
        case .conversation(let cid):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: cid)
        case .fuckYou(let item):
            return collectionView.dequeueConfiguredReusableCell(using: self.fuck,
                                                                for: indexPath,
                                                                item: item)
        }
    }
}

class FukCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Int

    var currentItem: Int?
    
    func configure(with item: Int) {
        
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.set(backgroundColor: .red)
    }
}
