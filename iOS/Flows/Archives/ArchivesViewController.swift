//
//  ArchiveViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 4/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchivesViewController: CollectionViewController<ArchivesCollectionViewManager.SectionType, ArchivesCollectionViewManager> {

    private lazy var archiveCollectionView = ArchivesCollectionView()

    var didSelectPost: ((Post) -> Void)? = nil

    override func initializeViews() {
        super.initializeViews()
        
        self.view.alpha = 0

        self.collectionViewManager.$onSelectedItem.mainSink { (result) in
            guard let selection = result else { return }
            switch selection.section {
            case .posts:
                if let post = selection.item as? Post {
                    self.didSelectPost?(post)
                }
            }
        }.store(in: &self.cancellables)

        FeedManager.shared.$selectedFeed.mainSink { feeds in
            if self.view.alpha == 1.0 {
                self.collectionViewManager.loadPosts()
            }
        }.store(in: &self.cancellables)
    }

    override func getCollectionView() -> CollectionView {
        return self.archiveCollectionView
    }

    func animate(show: Bool) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.view.alpha = show ? 1.0 : 0
        } completion: { _ in
            
            if let feed = FeedManager.shared.feeds.first(where: { feed in
                return feed.owner == User.current()
            }) {
                if self.view.alpha == 1.0 {
                    FeedManager.shared.selectedFeed = feed 
                }
            }
        }
    }
}
