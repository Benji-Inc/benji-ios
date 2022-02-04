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
        case wallet
    }

    enum ItemType: Hashable {
        case transaction(Transaction)
    }

    private let transactionConfig = ManageableCellRegistration<TransactionCell>().provider
    private let headerConfig = ManageableFooterRegistration<WalletHeaderView>().provider
        
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
        }
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView, kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
        return header
    }
}
