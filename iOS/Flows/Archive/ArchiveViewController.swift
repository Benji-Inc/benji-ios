//
//  ArchiveViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 4/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchiveViewController: CollectionViewController<ArchiveCollectionViewManager.SectionType, ArchiveCollectionViewManager> {

    private lazy var archiveCollectionView = ChannelsCollectionView()

    override func initializeViews() {
        super.initializeViews()

        self.collectionViewManager.$onSelectedItem.mainSink { (result) in
            guard let selection = result else { return }
            switch selection.section {
            case .posts:
                break 
            }
        }.store(in: &self.cancellables)
    }

    override func getCollectionView() -> CollectionView {
        return self.archiveCollectionView
    }
}
