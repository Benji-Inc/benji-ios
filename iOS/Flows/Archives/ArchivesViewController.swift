//
//  ArchiveViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 4/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchivesViewController: CollectionViewController<ArchivesCollectionViewManager.SectionType, ArchivesCollectionViewManager> {

    lazy var userCollectionVC = UserCollectionViewController()

    private lazy var archiveCollectionView = ArchivesCollectionView()

    private let gradientView = GradientView(with: [Color.background1.color.withAlphaComponent(1.0).cgColor,
                                                   Color.background1.color.withAlphaComponent(0).cgColor].reversed(), startPoint: .topCenter, endPoint: .bottomCenter)

    var didSelectPost: ((Post) -> Void)? = nil
    var didSelectClose: CompletionOptional = nil
    
    private let button = Button()

    override func initializeViews() {
        super.initializeViews()
        
        self.view.alpha = 0

        self.addChild(self.userCollectionVC)
        self.view.insertSubview(self.userCollectionVC.view, aboveSubview: self.archiveCollectionView)

        self.view.insertSubview(self.button, aboveSubview: self.archiveCollectionView)
        self.button.set(style: .icon(image: UIImage(systemName: "chevron.compact.up")!, color: .purple))
        self.button.didSelect { [unowned self] in
            UIView.animate(withDuration: 0.2) {
                self.view.alpha = 0 
            }
            self.didSelectClose?()
        }

        self.view.insertSubview(self.gradientView, belowSubview: self.button)

        self.collectionViewManager.$onSelectedItem.mainSink { (result) in
            guard let selection = result else { return }
            switch selection.section {
            case .user, .empty:
                break 
            case .posts, .upcoming:
                if let post = selection.item as? Post {
                    self.didSelectPost?(post)
                }
            }
        }.store(in: &self.cancellables)

        self.userCollectionVC.collectionViewManager.$onSelectedItem.mainSink { (cellItem) in
            guard let user = cellItem?.item as? User else { return }
            self.loadPosts(for: user)
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

        self.userCollectionVC.view.expandToSuperviewWidth()
        self.userCollectionVC.view.height = UserCollectionViewController.height
        self.userCollectionVC.view.pinToSafeArea(.top, padding: 0)

        self.button.setSize(with: self.view.width)
        self.button.pinToSafeArea(.bottom, padding: Theme.contentOffset)
        self.button.centerOnX()

        self.gradientView.expandToSuperviewWidth()
        self.gradientView.height = self.button.height + Theme.contentOffset
        self.gradientView.pin(.bottom)
    }

    func animate(show: Bool) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.view.alpha = show ? 1.0 : 0
        } completion: { _ in
            if self.view.alpha == 1.0 {
                self.didFinishShowing()
            } else {
                self.collectionViewManager.reset()
            }
        }
    }

    func didFinishShowing() {
        UserDefaultsManager.update(key: .hasShownHomeSwipe, with: true)
        if self.userCollectionVC.collectionViewManager.collectionView.numberOfSections == 0 {
            self.userCollectionVC.collectionViewManager.loadFeeds { [unowned self] in
                self.userCollectionVC.collectionViewManager.select(indexPath: IndexPath(item: 0, section: 0))
            }
        } else {
            self.userCollectionVC.collectionViewManager.select(indexPath: IndexPath(item: 0, section: 0))
        }
    }
}
