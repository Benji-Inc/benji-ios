//
//  ConnectionsViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConnectionsViewController: DiffableCollectionViewController<ConnectionsDataSource.SectionType,
                                    ConnectionsDataSource.ItemType,
                                 ConnectionsDataSource> {
    
    init() {
        super.init(with: ConnectionsCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadInitialData()
    }
    
    override func getAllSections() -> [ConnectionsDataSource.SectionType] {
        return ConnectionsDataSource.SectionType.allCases
    }
    
    override func retrieveDataForSnapshot() async -> [ConnectionsDataSource.SectionType : [ConnectionsDataSource.ItemType]] {
        var data: [ConnectionsDataSource.SectionType: [ConnectionsDataSource.ItemType]] = [:]
        
        try? await PeopleStore.shared.initializeIfNeeded()
        
        data[.connections] = PeopleStore.shared.connectedPeople.filter({ type in
            return !type.isCurrentUser
        }).sorted(by: { lhs, rhs in
            guard let lhsUpdated = lhs.updatedAt,
                  let rhsUpdated = rhs.updatedAt else { return false }
            return lhsUpdated > rhsUpdated
        }).compactMap({ type in
            return .memberId(type.personId)
        })
        
        let addItems: [ConnectionsDataSource.ItemType] = PeopleStore.shared.sortedUnclaimedReservationWithoutContact.compactMap { reservation in
            guard let id = reservation.objectId else { return nil }
            return .add(id)
        }
        
        data[.connections]?.append(contentsOf: addItems)
        
        return data
    }
}
