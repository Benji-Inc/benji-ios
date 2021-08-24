//
//  CollectionViewDataSource.swift
//  CollectionViewDataSource
//
//  Created by Martin Young on 8/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import UIKit

/// A protocol for types that can create a UICollectionViewDiffableDataSource.
/// Implementing types provide a means to dequeue collection view cells and supplementary views.
/// A data source creation function is automatically implemented by default and uses the dequeing functions
/// to initialize a new datasource.
protocol CollectionViewDataSourceCreator {

    associatedtype SectionType: Hashable
    associatedtype ItemIdentifier: Hashable

    typealias DataSourceType = UICollectionViewDiffableDataSource<SectionType, ItemIdentifier>

    /// Returns a configured UICollectionViewCell dequeued from the passed in collection view.
    func dequeueCell(with collectionView: UICollectionView,
                     indexPath: IndexPath,
                     identifier: ItemIdentifier) -> UICollectionViewCell?

    /// Returns a configured supplemental view dequeued from the passed in collection view.
    func dequeueSupplementaryView(with collectionView: UICollectionView,
                                  kind: String,
                                  indexPath: IndexPath) -> UICollectionReusableView?
}

extension CollectionViewDataSourceCreator {

    /// Returned a UICollectionViewDiffableDataSource initialized with a cell provider.
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
