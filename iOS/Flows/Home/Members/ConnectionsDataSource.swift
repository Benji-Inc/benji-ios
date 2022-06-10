//
//  ConnectionsDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConnectionsDataSource: CollectionViewDataSource<ConnectionsDataSource.SectionType, ConnectionsDataSource.ItemType> {
    
    enum SectionType: Int, CaseIterable {
        case connections
    }
    
    enum ItemType: Hashable {
        case memberId(String)
        case add(String)
    }
    
    private let config = ManageableCellRegistration<RoomMemberCell>().provider
    private let addConfig = ManageableCellRegistration<MemberAddCell>().provider
    
    // MARK: - Cell Dequeueing
    
    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {
        switch item {

        case .memberId(let member):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: member)

        case .add(let reservationId):
            return collectionView.dequeueConfiguredReusableCell(using: self.addConfig,
                                                                for: indexPath,
                                                                item: reservationId)
        }
    }
}

