//
//  CicleViewController.swift
//  CicleViewController
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleViewController: DiffableCollectionViewController<CircleCollectionViewDataSource.SectionType, CircleCollectionViewDataSource.ItemType, CircleCollectionViewDataSource> {

    // MARK: - UI

    private let circleGroup: CircleGroup

    init(with circleGroup: CircleGroup) {
        self.circleGroup = circleGroup
        super.init(with: CollectionView(layout: CircleCollectionViewLayout()))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Data Loading

    override func getAllSections() -> [CircleCollectionViewDataSource.SectionType] {
        return CircleCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [CircleCollectionViewDataSource.SectionType : [CircleCollectionViewDataSource.ItemType]] {

        let items: [CircleCollectionViewDataSource.ItemType] = self.circleGroup.circles?.first?.users?.compactMap { user in
            return .user(user)
        } ?? []

        var data: [CircleCollectionViewDataSource.SectionType : [CircleCollectionViewDataSource.ItemType]] = [:]
        data[.users] = items
        return data
    }
}
