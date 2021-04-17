//
//  FeedCollectionViewManager.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FeedCollectionViewManger: CollectionViewManager<FeedCollectionViewManger.SectionType> {

    enum SectionType: Int, ManagerSectionType {
        case feed = 0
    }

    private let config = ManageableCellRegistration<FeedCell>().cellProvider

    func loadFeeds() {
        self.collectionView.animationView.play()

        FeedManager.shared.$feeds.mainSink { feeds in
            let cycle = AnimationCycle(inFromPosition: .inward, outToPosition: .inward, shouldConcatenate: true, scrollToEnd: false)
            self.loadSnapshot(animationCycle: cycle)
                .mainSink { _ in
                    self.collectionView.animationView.stop()
                }.store(in: &self.cancellables)
        }.store(in: &self.cancellables)
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        switch section {
        case .feed:
            return FeedManager.shared.feeds
        }
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        switch section {
        case .feed:
            return self.collectionView.dequeueManageableCell(using: self.config,
                                                             for: indexPath,
                                                             item: item as? Feed)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.height * 0.74 + Theme.contentOffset, height: self.collectionView.height)
    }
}
