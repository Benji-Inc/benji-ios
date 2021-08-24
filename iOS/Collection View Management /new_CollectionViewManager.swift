//
//  new_CollectionViewManager.swift
//  new_CollectionViewManager
//
//  Created by Martin Young on 8/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import UIKit

class CollectionViewManager<SectionType: Hashable, ItemIdentifier: Hashable> {

    typealias DataSourceType = UICollectionViewDiffableDataSource<SectionType, ItemIdentifier>

    private(set) lazy var dataSource: DataSourceType = self.createDataSource()
    private unowned let collectionView: UICollectionView

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    private func createDataSource() -> DataSourceType {
        let dataSource = DataSourceType(collectionView: self.collectionView)
        { (collectionView: UICollectionView, indexPath: IndexPath, item: ItemIdentifier) -> UICollectionViewCell? in

            return self.dequeueCell(with: collectionView, indexPath: indexPath, identifier: item)
        }

        dataSource.supplementaryViewProvider =
        { (collectionView: UICollectionView, kind: String, IndexPath: IndexPath) -> UICollectionReusableView? in
            return self.getSupplementaryView(with: collectionView, kind: kind, indexPath: IndexPath)
        }

        return dataSource
    }

    func initializeData() { }

    func dequeueCell(with collectionView: UICollectionView,
                     indexPath: IndexPath,
                     identifier: ItemIdentifier) -> UICollectionViewCell? {
        return nil
    }

    func getSupplementaryView(with collectionView: UICollectionView,
                              kind: String,
                              indexPath: IndexPath) -> UICollectionReusableView? {
        return nil
    }

    func loadSnapshot(animationCycle: AnimationCycle? = nil, animatingDifferences: Bool = false) async {
        let snapshot = await self.dataSource.snapshot()

        if let cycle = animationCycle {
            await self.animateOut(position: cycle.outToPosition, concatenate: cycle.shouldConcatenate)
            await self.dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
            await self.animateIn(position: cycle.inFromPosition, concatenate: cycle.shouldConcatenate)
        } else {
            await self.dataSource.apply(snapshot, animatingDifferences: false)
        }
    }
}


extension CollectionViewManager {

    @MainActor
    func animateOut(position: AnimationPosition, concatenate: Bool) async {
        let visibleCells = self.collectionView.visibleCells

        guard visibleCells.count > 0 else {
            self.collectionView.alpha = 0
            return
        }

        let duration: TimeInterval = Theme.animationDuration
        var longestDelay: TimeInterval = 0

        for (index, cell) in visibleCells.enumerated() {
            cell.alpha = 1.0
            let delay: TimeInterval = concatenate ? duration/Double(visibleCells.count)*Double(index) : 0
            UIView.animate(withDuration: duration, delay: delay, options: .curveEaseInOut, animations: {
                cell.transform = position.getTransform(for: cell)
                cell.alpha = 0.0
            })
            longestDelay = delay
        }

        await Task.sleep(seconds: duration + longestDelay)

        self.collectionView.alpha = 0
    }

    @MainActor
    func animateIn(position: AnimationPosition, concatenate: Bool) async {
        let visibleCells = self.collectionView.visibleCells

        guard visibleCells.count > 0 else {
            self.collectionView.alpha = 1
            return
        }

        let duration: TimeInterval = Theme.animationDuration
        var longestDelay: TimeInterval = 0

        for (index, cell) in visibleCells.enumerated() {
            cell.alpha = 0.0
            cell.transform = position.getTransform(for: cell)
            self.collectionView.alpha = 1
            let delay: TimeInterval = concatenate ? duration/Double(visibleCells.count)*Double(index) : 0
            UIView.animate(withDuration: duration, delay: delay, options: .curveEaseInOut, animations: {
                cell.transform = .identity
                cell.alpha = 1.0
            })
            longestDelay = delay
        }

        await Task.sleep(seconds: duration + longestDelay)
    }
}
