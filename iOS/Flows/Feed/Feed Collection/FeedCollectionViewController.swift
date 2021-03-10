//
//  FeedCollectionViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FeedCollectionViewController: CollectionViewController<FeedCollectionViewManger.SectionType, FeedCollectionViewManger> {

    override func getCollectionView() -> CollectionView {
        return FeedCollectionView()
    }

    override func initializeViews() {
        super.initializeViews()

        self.collectionViewManager.$onSelectedItem.mainSink { (cellItem) in
            guard let item = cellItem?.item as? FakeItem else { return }
            //self.delegate.attachementView(self, didSelect: attachment)
        }.store(in: &self.cancellables)
    }
}
