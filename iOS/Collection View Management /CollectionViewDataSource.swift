//
//  CollectionViewDataSource.swift
//  CollectionViewDataSource
//
//  Created by Martin Young on 8/25/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

/// A base class for types that can act as a data source for a UICollectionview.
/// Subclasses should override functions related to dequeuing cells and supplementary views.
/// This class works the same as UICollectionViewDiffableDataSource but it allows you to subclass it more easily and hold additional state.
@MainActor
class CollectionViewDataSource<SectionType: Hashable, ItemType: Hashable> {

    typealias DiffableDataSourceType = UICollectionViewDiffableDataSource<SectionType, ItemType>
    typealias SnapshotType = NSDiffableDataSourceSnapshot<SectionType, ItemType>

    private var diffableDataSource: DiffableDataSourceType!

    required init(collectionView: UICollectionView) {
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

// These functions just forward to the corresponding functions in the underlying NSDiffableDataSource
extension CollectionViewDataSource {

    // MARK: - Standard DataSource Functions

    func apply(_ snapshot: SnapshotType, animatingDifferences: Bool = true) {
        self.diffableDataSource.apply(snapshot, animatingDifferences: animatingDifferences, completion: nil)
    }

    func apply(_ snapshot: SnapshotType, animatingDifferences: Bool = true) async {
        await self.diffableDataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    func applySnapshotUsingReloadData(_ snapshot: SnapshotType) async {
        await self.diffableDataSource.applySnapshotUsingReloadData(snapshot)
    }

    func snapshot() -> SnapshotType {
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

// MARK: - Snapshot Convenience Functions

extension CollectionViewDataSource {

    // MARK: - Synchronous Functions

    func applyChanges(_ changes: (inout SnapshotType) -> Void) {
        var snapshot = self.snapshot()
        changes(&snapshot)
        self.apply(snapshot)
    }

    func appendItems(_ identifiers: [ItemType], toSection sectionIdentifier: SectionType? = nil) {
        self.applyChanges { snapshot in
            snapshot.appendItems(identifiers, toSection: sectionIdentifier)
        }
    }

    func insertItems(_ identifiers: [ItemType], in section: SectionType, atIndex index: Int) {
        self.applyChanges { snapshot in
            snapshot.insertItems(identifiers, in: section, atIndex: index)
        }
    }

    func insertItems(_ identifiers: [ItemType], beforeItem beforeIdentifier: ItemType) {
        self.applyChanges { snapshot in
            snapshot.insertItems(identifiers, beforeItem: beforeIdentifier)
        }
    }

    func insertItems(_ identifiers: [ItemType], afterItem afterIdentifier: ItemType) {
        self.applyChanges { snapshot in
            snapshot.insertItems(identifiers, afterItem: afterIdentifier)
        }
    }

    func deleteItems(_ identifiers: [ItemType]) {
        self.applyChanges { snapshot in
            snapshot.deleteItems(identifiers)
        }
    }

    func deleteAllItems() {
        self.applyChanges { snapshot in
            snapshot.deleteAllItems()
        }
    }

    func moveItem(_ identifier: ItemType, beforeItem toIdentifier: ItemType) {
        self.applyChanges { snapshot in
            snapshot.moveItem(identifier, beforeItem: toIdentifier)
        }
    }

    func moveItem(_ identifier: ItemType, afterItem toIdentifier: ItemType) {
        self.applyChanges { snapshot in
            snapshot.moveItem(identifier, afterItem: toIdentifier)
        }
    }

    func reloadItems(_ identifiers: [ItemType]) {
        self.applyChanges { snapshot in
            snapshot.reloadItems(identifiers)
        }
    }

    func reconfigureItems(_ identifiers: [ItemType]) {
        self.applyChanges { snapshot in
            snapshot.reconfigureItems(identifiers)
        }
    }

    func reconfigureItem(atIndex index: Int, in section: SectionType) {
        self.applyChanges { snapshot in
            snapshot.reconfigureItem(atIndex: index, in: section)
        }
    }

    func appendSections(_ identifiers: [SectionType]) {
        self.applyChanges { snapshot in
            snapshot.appendSections(identifiers)
        }
    }

    func insertSections(_ identifiers: [SectionType], beforeSection toIdentifier: SectionType) {
        self.applyChanges { snapshot in
            snapshot.insertSections(identifiers, beforeSection: toIdentifier)
        }
    }

    func insertSections(_ identifiers: [SectionType], afterSection toIdentifier: SectionType) {
        self.applyChanges { snapshot in
            snapshot.insertSections(identifiers, afterSection: toIdentifier)
        }
    }

    func deleteSections(_ identifiers: [SectionType]) {
        self.applyChanges { snapshot in
            snapshot.deleteSections(identifiers)
        }
    }

    func moveSection(_ identifier: SectionType, beforeSection toIdentifier: SectionType) {
        self.applyChanges { snapshot in
            snapshot.moveSection(identifier, beforeSection: toIdentifier)
        }
    }

    func moveSection(_ identifier: SectionType, afterSection toIdentifier: SectionType) {
        self.applyChanges { snapshot in
            snapshot.moveSection(identifier, afterSection: toIdentifier)
        }
    }

    func reloadSections(_ identifiers: [SectionType]) {
        self.applyChanges { snapshot in
            snapshot.reloadSections(identifiers)
        }
    }

    // Asynchronous Functions

    func applyChanges(_ changes: (inout SnapshotType) -> Void) async {
        var snapshot = self.snapshot()
        changes(&snapshot)
        await self.apply(snapshot)
    }

    func appendItems(_ identifiers: [ItemType], toSection sectionIdentifier: SectionType? = nil) async {
        await self.applyChanges { snapshot in
            snapshot.appendItems(identifiers, toSection: sectionIdentifier)
        }
    }

    func insertItems(_ identifiers: [ItemType], in section: SectionType, atIndex index: Int) async {
        await self.applyChanges { snapshot in
            snapshot.insertItems(identifiers, in: section, atIndex: index)
        }
    }

    func insertItems(_ identifiers: [ItemType], beforeItem beforeIdentifier: ItemType) async {
        await self.applyChanges { snapshot in
            snapshot.insertItems(identifiers, beforeItem: beforeIdentifier)
        }
    }

    func insertItems(_ identifiers: [ItemType], afterItem afterIdentifier: ItemType) async {
        await self.applyChanges { snapshot in
            snapshot.insertItems(identifiers, afterItem: afterIdentifier)
        }
    }

    func deleteItems(_ identifiers: [ItemType]) async {
        await self.applyChanges { snapshot in
            snapshot.deleteItems(identifiers)
        }
    }

    func deleteAllItems() async {
        await self.applyChanges { snapshot in
            snapshot.deleteAllItems()
        }
    }

    func moveItem(_ identifier: ItemType, beforeItem toIdentifier: ItemType) async {
        await self.applyChanges { snapshot in
            snapshot.moveItem(identifier, beforeItem: toIdentifier)
        }
    }

    func moveItem(_ identifier: ItemType, afterItem toIdentifier: ItemType) async {
        await self.applyChanges { snapshot in
            snapshot.moveItem(identifier, afterItem: toIdentifier)
        }
    }

    func reloadItems(_ identifiers: [ItemType]) async {
        await self.applyChanges { snapshot in
            snapshot.reloadItems(identifiers)
        }
    }

    func reconfigureItems(_ identifiers: [ItemType]) async {
        await self.applyChanges { snapshot in
            snapshot.reconfigureItems(identifiers)
        }
    }

    func appendSections(_ identifiers: [SectionType]) async {
        await self.applyChanges { snapshot in
            snapshot.appendSections(identifiers)
        }
    }

    func insertSections(_ identifiers: [SectionType], beforeSection toIdentifier: SectionType) async {
        await self.applyChanges { snapshot in
            snapshot.insertSections(identifiers, beforeSection: toIdentifier)
        }
    }

    func insertSections(_ identifiers: [SectionType], afterSection toIdentifier: SectionType) async {
        await self.applyChanges { snapshot in
            snapshot.insertSections(identifiers, afterSection: toIdentifier)
        }
    }

    func deleteSections(_ identifiers: [SectionType]) async {
        await self.applyChanges { snapshot in
            snapshot.deleteSections(identifiers)
        }
    }

    func moveSection(_ identifier: SectionType, beforeSection toIdentifier: SectionType) async {
        await self.applyChanges { snapshot in
            snapshot.moveSection(identifier, beforeSection: toIdentifier)
        }
    }

    func moveSection(_ identifier: SectionType, afterSection toIdentifier: SectionType) async {
        await self.applyChanges { snapshot in
            snapshot.moveSection(identifier, afterSection: toIdentifier)
        }
    }

    func reloadSections(_ identifiers: [SectionType]) async {
        await self.applyChanges { snapshot in
            snapshot.reloadSections(identifiers)
        }
    }
}

// MARK: - Custom Animations for Snapshots

// Functions to do custom animations to the collection view in conjunctions with applying snapshots.
extension CollectionViewDataSource {

    /// Animates the first part of the animation cycle, applies the snapshot, then finishes the animation cycle.
    @MainActor
    func apply(_ snapshot: SnapshotType,
               collectionView: UICollectionView,
               animationCycle: AnimationCycle) async {

        await collectionView.animateOut(position: animationCycle.outToPosition,
                                        concatenate: animationCycle.shouldConcatenate)

        await self.applySnapshotUsingReloadData(snapshot)

        // If specified, scroll to a particular item in the collection view.
        if let scrollToIndexPath = animationCycle.scrollToIndexPath,
           self.itemIdentifier(for: scrollToIndexPath).exists {

            collectionView.scrollToItem(at: scrollToIndexPath,
                                        at: [animationCycle.scrollPosition],
                                        animated: false)

            // Minor hack. Wait a tick so that the collection view has time to update its visible cells.
            // This ensures that the animate in animations work properly.
            await Task.sleep(seconds: 0.01)
        }
        
        await collectionView.animateIn(position: animationCycle.inFromPosition,
                                       concatenate: animationCycle.shouldConcatenate)
    }
}
