//
//  WalletCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WalletCollectionViewDataSource: CollectionViewDataSource<WalletCollectionViewDataSource.SectionType,
                                      WalletCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case achievements
        case transactions
    }

    enum ItemType: Hashable {
        case transaction(Transaction)
        case achievement(AchievementViewModel)
    }

    private let transactionConfig = ManageableCellRegistration<TransactionCell>().provider
    private let achievementConfig = ManageableCellRegistration<AchievementCell>().provider
                    
    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .transaction(let transaction):
            return collectionView.dequeueConfiguredReusableCell(using: self.transactionConfig,
                                                                for: indexPath,
                                                                item: transaction)
        case .achievement(let type):
            return collectionView.dequeueConfiguredReusableCell(using: self.achievementConfig,
                                                                for: indexPath,
                                                                item: type)
        }
    }
}
