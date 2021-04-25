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
    var didSelectClose: CompletionOptional = nil
    var didFinishShowing: CompletionOptional = nil
    
    private let button = Button()

    override func initializeViews() {
        super.initializeViews()
        
        self.view.alpha = 0

        self.view.insertSubview(self.button, aboveSubview: self.archiveCollectionView)
        self.button.set(style: .icon(image: UIImage(systemName: "chevron.compact.up")!, color: .purple))
        self.button.didSelect { [unowned self] in
            self.didSelectClose?()
        }

        self.collectionViewManager.$onSelectedItem.mainSink { (result) in
            guard let selection = result else { return }
            switch selection.section {
            case .user:
                break 
            case .posts:
                if let post = selection.item as? Post {
                    self.didSelectPost?(post)
                }
            }
        }.store(in: &self.cancellables)
    }

    func loadPosts(for user: User) {
        if self.view.alpha == 1.0 {
            self.collectionViewManager.loadPosts(for: user)
        }
    }

    override func getCollectionView() -> CollectionView {
        return self.archiveCollectionView
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.button.setSize(with: self.view.width)
        self.button.pinToSafeArea(.bottom, padding: Theme.contentOffset)
        self.button.centerOnX()
    }

    func animate(show: Bool) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.view.alpha = show ? 1.0 : 0
        } completion: { _ in
            if self.view.alpha == 1.0 {
                self.didFinishShowing?()
            } else {
                self.collectionViewManager.reset()
            }
        }
    }
}
