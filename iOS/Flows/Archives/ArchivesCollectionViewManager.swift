//
//  ArchiveCollectionViewManager.swift
//  Ours
//
//  Created by Benji Dodgson on 4/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class ArchivesCollectionViewManager: CollectionViewManager<ArchivesCollectionViewManager.SectionType> {

    enum SectionType: Int, ManagerSectionType {
        case posts
    }

    private let archiveConfig = ManageableCellRegistration<ArchiveCell>().provider
    private let headerConfig = ManageableHeaderRegistration<ArchiveHeaderView>().provider
    private let footerConfig = ManageableFooterRegistration<ArchiveFooterView>().provider

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
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Theme.contentOffset, bottom: 0, trailing: Theme.contentOffset)

        let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(180))
        let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

        let footerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(140))
        let footerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerItemSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)

        section.boundarySupplementaryItems = [headerItem, footerItem]

        return UICollectionViewCompositionalLayout(section: section)
    }()

    // Posts are sorted by createdBy
    private var posts: [Post] = []
    private var user: User?
    private var totalCount: Int = 0

    override func initialize() {
        super.initialize()

        self.collectionView.collectionViewLayout = self.layout
    }

    func loadPosts(for user: User) {
        self.user = user
        self.collectionView.animationView.play()

        let combined = Publishers.Zip(
            PostsSupplier.shared.getCountOfMediaPosts(for: user).assertNoFailure(),
            PostsSupplier.shared.queryForMediaPosts(for: user).assertNoFailure()
        )

        combined.mainSink { (result) in
            switch result {
            case (let count, let posts):
                self.posts = posts
                self.totalCount = count
                let cycle = AnimationCycle(inFromPosition: .inward, outToPosition: .inward, shouldConcatenate: true, scrollToEnd: false)
                self.loadSnapshot(animationCycle: cycle)
            }
            self.collectionView.animationView.stop()
        }.store(in: &self.cancellables)
    }

    func appendPosts(completion: CompletionOptional) {
        guard let user = self.user else { return }

        PostsSupplier.shared.queryForMediaPosts(before: self.posts.last?.createdAt, for: user)
            .mainSink { result in

            switch result {
            case .success(let posts):
                self.posts.append(contentsOf: posts)
                self.posts.removeDuplicates()
                self.loadSnapshot()
                completion?()
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

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = self.collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            if let user = self.user {
                header.configure(with: user)
            }
            return header 
        case UICollectionView.elementKindSectionFooter:
            let footer = self.collectionView.dequeueConfiguredReusableSupplementary(using: self.footerConfig, for: indexPath)
            footer.configure(showButton: self.posts.count < self.totalCount)
            footer.button.didSelect { [unowned self] in
                footer.button.handleEvent(status: .loading)
                self.appendPosts {
                    footer.button.handleEvent(status: .complete)
                }
            }
            return footer
        default:
            return nil
        }
    }
}
