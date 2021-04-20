//
//  ArchiveCollectionViewManager.swift
//  Ours
//
//  Created by Benji Dodgson on 4/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchivesCollectionViewManager: CollectionViewManager<ArchivesCollectionViewManager.SectionType> {

    enum SectionType: Int, ManagerSectionType {
        case posts
    }

    private let archiveConfig = ManageableCellRegistration<ArchiveCell>().cellProvider

    lazy var layout: UICollectionViewCompositionalLayout = {
        let widthFraction: CGFloat = 0.33
        let heightFraction: CGFloat = 0.45

        // Item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(widthFraction), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let inset: CGFloat = 1.5
        item.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)

        // Group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(heightFraction))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        // Section
        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }()

    @Published private var posts: [Post] = []

    override func initialize() {
        super.initialize()

        self.collectionView.collectionViewLayout = self.layout
        self.collectionView.animationView.play()

        self.$posts.mainSink { _ in
            self.loadSnapshot()
        }.store(in: &self.cancellables)
    }

    func load(feed: Feed) {
        FeedManager.shared.queryForAllMediaPosts(for: feed)
            .mainSink { result in
                switch result {
                case .success(let posts):
                    self.posts = posts
                case .error(_):
                    break
                }
            }.store(in: &self.cancellables)
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        switch section {
        case .posts:
            return self.posts
        }
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        switch section {
        case .posts:
            return self.collectionView.dequeueManageableCell(using: self.archiveConfig,
                                                             for: indexPath,
                                                             item: item as? Post)
        }
    }

}
