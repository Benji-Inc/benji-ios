//
//  FeedCollectionViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserCollectionViewController: CollectionViewController<UserCollectionViewManger.SectionType, UserCollectionViewManger> {

    static let height: CGFloat = 100

    var statusView: FeedStatusView? {
        guard let cv = self.collectionViewManager.collectionView as? UserCollectionView else { return nil }
        return cv.statusView
    }

    override func getCollectionView() -> CollectionView {
        return UserCollectionView()
    }

    override func initializeViews() {
        super.initializeViews()

        RitualManager.shared.$state
            .mainSink { state in
            switch state {
            case .feedAvailable:
                self.collectionViewManager.loadFeeds()
            default:
                self.collectionViewManager.reset()
            }
        }.store(in: &self.cancellables)
    }
}
