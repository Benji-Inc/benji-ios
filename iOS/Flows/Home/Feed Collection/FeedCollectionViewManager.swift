//
//  FeedCollectionViewManager.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class FeedCollectionViewManger: CollectionViewManager<FeedCollectionViewManger.SectionType> {

    enum SectionType: Int, ManagerSectionType {
        case feed = 0
    }

    private let config = ManageableCellRegistration<FeedCell>().provider

    lazy var layout: UICollectionViewCompositionalLayout = {
        let widthFraction: CGFloat = 0.2
        let heightFraction: CGFloat = 0.45

        // Item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(widthFraction), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let verticalInset: CGFloat = 10
        let horizontalInset: CGFloat = 5
        item.contentInsets = NSDirectionalEdgeInsets(top: verticalInset, leading: horizontalInset, bottom: verticalInset, trailing: horizontalInset)

        // Group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        // Section
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Theme.contentOffset, bottom: 0, trailing: Theme.contentOffset)
        return UICollectionViewCompositionalLayout(section: section)
    }()

    private var users: [User] = []

    func loadFeeds(completion: CompletionOptional = nil) {
        self.collectionView.collectionViewLayout = self.layout

        self.collectionView.animationView.play()

        let combined = Publishers.Zip(
            GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: []).assertNoFailure(),
            FeedManager.shared.$feeds
        )

        combined.mainSink { (result) in
            switch result {
            case (let connections, _):
                var usrs = [User.current()!]
                let connectedUsers = connections.compactMap { connection in
                    return connection.nonMeUser
                }
                usrs.append(contentsOf: connectedUsers)
                self.users = usrs
                self.loadSnapshot()
            }
            self.collectionView.animationView.stop()
            completion?()
        }.store(in: &self.cancellables)
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        switch section {
        case .feed:
            return self.users
        }
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        switch section {
        case .feed:
            return self.collectionView.dequeueManageableCell(using: self.config,
                                                             for: indexPath,
                                                             item: item as? User)
        }
    }
}
