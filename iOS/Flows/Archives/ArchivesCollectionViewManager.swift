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

    private let archiveConfig = ManageableCellRegistration<ArchiveCell>().provider
    private let headerConfig = ManageableHeaderRegistration<ArchiveHeaderView>().provider

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
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Theme.contentOffset, bottom: 100, trailing: Theme.contentOffset)

        let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40))
        let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: "header", alignment: .top)
        section.boundarySupplementaryItems = [headerItem]

        return UICollectionViewCompositionalLayout(section: section)
    }()

    private var posts: [Post] = []

    override func initialize() {
        super.initialize()

        self.collectionView.collectionViewLayout = self.layout
    }

    func loadPosts(for user: User) {

        self.collectionView.animationView.play()
        PostsSupplier.shared.queryForAllMediaPosts(for: user)
            .mainSink { result in

            switch result {
            case .success(let posts):
                self.posts = posts
                let cycle = AnimationCycle(inFromPosition: .inward, outToPosition: .inward, shouldConcatenate: true, scrollToEnd: false)
                self.loadSnapshot(animationCycle: cycle)
            case .error(_):
                break
            }

            self.collectionView.animationView.stop()
        }.store(in: &self.cancellables)
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        return self.posts
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        return self.collectionView.dequeueManageableCell(using: self.archiveConfig,
                                                         for: indexPath,
                                                         item: item as? Post)
    }

    override func getSupplementaryView(for section: SectionType, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {
        return self.collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
    }
}
