//
//  CollectionViewDataSource.swift
//  CollectionViewDataSource
//
//  Created by Martin Young on 8/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import UIKit

protocol CollectionViewDataSourceCreator {

    associatedtype SectionType: Hashable
    associatedtype ItemIdentifier: Hashable

    typealias DataSourceType = UICollectionViewDiffableDataSource<SectionType, ItemIdentifier>

    func dequeueCell(with collectionView: UICollectionView,
                     indexPath: IndexPath,
                     identifier: ItemIdentifier) -> UICollectionViewCell?

    func dequeueSupplementaryView(with collectionView: UICollectionView,
                                  kind: String,
                                  indexPath: IndexPath) -> UICollectionReusableView?
}

extension CollectionViewDataSourceCreator {

    func createDataSource(for collectionView: UICollectionView) -> DataSourceType {
        let dataSource = DataSourceType(collectionView: collectionView)
        { (collectionView: UICollectionView, indexPath: IndexPath, item: ItemIdentifier) -> UICollectionViewCell? in

            return self.dequeueCell(with: collectionView, indexPath: indexPath, identifier: item)
        }

        dataSource.supplementaryViewProvider =
        { (collectionView: UICollectionView, kind: String, IndexPath: IndexPath) -> UICollectionReusableView? in
            return self.dequeueSupplementaryView(with: collectionView, kind: kind, indexPath: IndexPath)
        }

        return dataSource
    }
}
