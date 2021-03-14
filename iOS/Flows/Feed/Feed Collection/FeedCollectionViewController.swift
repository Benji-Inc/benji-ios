//
//  FeedCollectionViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FeedCollectionViewController: CollectionViewController<FeedCollectionViewManger.SectionType, FeedCollectionViewManger> {

    static let height: CGFloat = 100

    var statusView: FeedStatusView? {
        guard let cv = self.collectionViewManager.collectionView as? FeedCollectionView else { return nil }
        return cv.statusView
    }

    override func getCollectionView() -> CollectionView {
        return FeedCollectionView()
    }

    override func initializeViews() {
        super.initializeViews()

        self.collectionViewManager.$onSelectedItem.mainSink { (cellItem) in
            guard let item = cellItem?.item as? Feed else { return }
            FeedManager.shared.selectedFeed = item 
        }.store(in: &self.cancellables)
    }
}
