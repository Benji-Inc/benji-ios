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
        case user
        case upcoming
        case posts
    }

    private let archiveConfig = ManageableCellRegistration<ArchiveCell>().provider
    private let userConfig = ManageableCellRegistration<UserHeaderCell>().provider
    private let footerConfig = ManageableFooterRegistration<ArchiveFooterView>().provider
    private let headerConfig = ManageableHeaderRegistration<ArchiveHeaderView>().provider

    lazy var layout = UICollectionViewCompositionalLayout() { sectionIndex, layoutEnvironment in

        guard let sectionType = SectionType(rawValue: sectionIndex) else { return nil }

        switch sectionType {
        case .user:
            // Item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: UserCollectionViewController.height, leading: Theme.contentOffset, bottom: 0, trailing: Theme.contentOffset)

            return section
        case .upcoming:
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

            let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40))
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

            section.boundarySupplementaryItems = [headerItem]

            return section
        case .posts:
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

            let footerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(160))
            let footerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerItemSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)

            let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40))
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

            section.boundarySupplementaryItems = [headerItem, footerItem]

            return section
        }
    }

    // Posts are sorted by createdBy
    private var posts: [Post] = []
    private var upcomingPosts: [Post] = []
    private var user: User?
    private var totalCount: Int = 0

    override func initialize() {
        super.initialize()

        self.collectionView.collectionViewLayout = self.layout
    }

    func reloadForExistingUser() {
        guard let user = self.user else { return }
        self.loadPosts(for: user)
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
                self.sortAndSet(posts: posts)
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
                let nonUpcomingPosts = posts.filter { post in
                    return !self.upcomingPosts.contains(post)
                }
                self.posts.append(contentsOf: nonUpcomingPosts)
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
        switch section {
        case .user:
            if let u = self.user {
                return [u]
            } else {
                return []
            }
        case .upcoming:
            return self.upcomingPosts
        case .posts:
            return self.posts
        }

    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        switch section {
        case .user:
            return self.collectionView.dequeueManageableCell(using: self.userConfig,
                                                             for: indexPath,
                                                             item: self.user)
        case .posts, .upcoming:
            return self.collectionView.dequeueManageableCell(using: self.archiveConfig,
                                                             for: indexPath,
                                                             item: item as? Post)
        }
    }

    override func getSupplementaryView(for section: SectionType, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {

        switch kind {
        case UICollectionView.elementKindSectionHeader:

            let header = self.collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            if section == .upcoming {
                header.label.setText("Upcoming")
            } else {
                header.label.setText("Previous")
            }
            header.layoutNow()
            return header
        case UICollectionView.elementKindSectionFooter:
            let footer = self.collectionView.dequeueConfiguredReusableSupplementary(using: self.footerConfig, for: indexPath)
            footer.configure(showButton: self.posts.count < (self.totalCount - self.upcomingPosts.count))
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

    private func sortAndSet(posts: [Post]) {
        var today: [Post] = []
        var past: [Post] = []

        posts.forEach { post in
            if let trigger = post.triggerDate, trigger.isSameDateOrInFuture(for: Date()) {
                today.append(post)
            } else {
                past.append(post)
            }
        }

        self.upcomingPosts = today
        self.posts = past
    }

    // MARK: Menu overrides

    override func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemAt indexPath: IndexPath,
                                 point: CGPoint) -> UIContextMenuConfiguration? {
        guard let section = SectionType(rawValue: indexPath.section) else { return nil }

        var post: Post?
        switch section {
        case .user:
            return nil
        case .upcoming:
            post = self.upcomingPosts[safe: indexPath.row]
        case .posts:
            post = self.posts[safe: indexPath.row]
        }

        guard let p = post, let cell = collectionView.cellForItem(at: indexPath) as? ArchiveCell else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
            return ArchivePreviewViewController(with: p, size: cell.size)
        }, actionProvider: { suggestedActions in
            if p.author == User.current() {
                return self.makeCurrentUsertMenu(for: p, at: indexPath)
            } else {
                return self.makeNonCurrentUserMenu(for: p, at: indexPath)
            }
        })
    }
}
