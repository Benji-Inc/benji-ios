//
//  FeedCollectionViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FeedCollectionViewController: CollectionViewController<FeedCollectionViewManger.SectionType, FeedCollectionViewManger> {

    static let height: CGFloat = 60

    var statusView: FeedStatusView? {
        guard let cv = self.collectionViewManager.collectionView as? FeedCollectionView else { return nil }
        return cv.statusView
    }

    override func getCollectionView() -> CollectionView {
        return FeedCollectionView()
    }

    override func initializeViews() {
        super.initializeViews()

        RitualManager.shared.$state.mainSink { state in
            switch state {
            case .feedAvailable:
                self.collectionViewManager.loadFeeds()
            default:
                self.collectionViewManager.reset()
            }
        }.store(in: &self.cancellables)
    }
}
