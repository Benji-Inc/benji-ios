//
//  CollectionViewDataSource.swift
//  CollectionViewDataSource
//
//  Created by Martin Young on 8/25/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A base class for types that can act as a data source for a UICollectionview.
/// Subclasses should override functions related to dequeuing cells and supplementary views.
/// This class works the same as UICollectionViewDiffableDataSource but it allows you to subclass it more easily and hold additional state.
class CollectionViewDataSource<SectionType: Hashable, ItemType: Hashable> {

    typealias DiffableDataSourceType = UICollectionViewDiffableDataSource<SectionType, ItemType>

    private var diffableDataSource: DiffableDataSourceType!

    init(collectionView: UICollectionView) {
        self.diffableDataSource = DiffableDataSourceType(collectionView: collectionView,
                                                         cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let section = self.sectionIdentifier(for: indexPath.section) else { return nil }

            return self.dequeueCell(with: collectionView,
                                    indexPath: indexPath,
                                    section: section,
                                    item: itemIdentifier)
        })

        self.diffableDataSource.supplementaryViewProvider =
        { (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            guard let section = self.sectionIdentifier(for: indexPath.section) else { return nil }

            return self.dequeueSupplementaryView(with: collectionView,
                                                 kind: kind,
                                                 section: section,
                                                 indexPath: indexPath)
        }

    }
    /// Returns a configured UICollectionViewCell dequeued from the passed in collection view.
    func dequeueCell(with collectionView: UICollectionView,
                     indexPath: IndexPath,
                     section: SectionType,
                     item: ItemType) -> UICollectionViewCell? {
        fatalError()
    }

    /// Returns a configured supplemental view dequeued from the passed in collection view.
    func dequeueSupplementaryView(with collectionView: UICollectionView,
                                  kind: String,
                                  section: SectionType,
                                  indexPath: IndexPath) -> UICollectionReusableView? {
        return nil
    }
}


// MARK: - NSDiffableDataSource Functions

// These functions just forward to the corresponding functions to the underlying NSDiffableDataSource
extension CollectionViewDataSource {

    func apply(_ snapshot: NSDiffableDataSourceSnapshot<SectionType, ItemType>,
               animatingDifferences: Bool = true) async {

        await self.diffableDataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    func applySnapshotUsingReloadData(_ snapshot: NSDiffableDataSourceSnapshot<SectionType, ItemType>) async {
        await self.diffableDataSource.applySnapshotUsingReloadData(snapshot)
    }

    func snapshot() -> NSDiffableDataSourceSnapshot<SectionType, ItemType> {
        return self.diffableDataSource.snapshot()
    }

    func sectionIdentifier(for index: Int) -> SectionType? {
        return self.diffableDataSource.sectionIdentifier(for: index)
    }

    func index(for sectionIdentifier: SectionType) -> Int? {
        return self.diffableDataSource.index(for: sectionIdentifier)
    }

    func itemIdentifier(for indexPath: IndexPath) -> ItemType? {
        return self.diffableDataSource.itemIdentifier(for: indexPath)
    }

    func indexPath(for itemIdentifier: ItemType) -> IndexPath? {
        return self.diffableDataSource.indexPath(for: itemIdentifier)
    }
}

// MARK: - Custom Animations for Snapshots

// Functions to do custom animations to the collection view in conjunctions with applying snapshots.
extension CollectionViewDataSource {

    /// Animates the first part of the animation cycle, applies the snapshot, then finishes the animation cycle.
    func apply(_ snapshot: NSDiffableDataSourceSnapshot<SectionType, ItemType>,
               collectionView: UICollectionView,
               animationCycle: AnimationCycle,
               animatingDifferences: Bool = false) async {

        await collectionView.animateOut(position: animationCycle.outToPosition,
                                        concatenate: animationCycle.shouldConcatenate)

        await self.apply(snapshot, animatingDifferences: animatingDifferences)

        await collectionView.animateIn(position: animationCycle.inFromPosition,
                                       concatenate: animationCycle.shouldConcatenate)
    }
}
