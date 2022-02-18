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
        case reward
        case transactions
    }

    enum ItemType: Hashable {
        case transaction(Transaction)
        case reward(Bool)
    }

    private let transactionConfig = ManageableCellRegistration<TransactionCell>().provider
                    
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
        case .reward(let reward):
            return nil 
        }
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        
//        switch section {
//        case .transactions:
//            if kind == BackgroundSupplementaryView.kind {
//                let background = collectionView.dequeueConfiguredReusableSupplementary(using: self.backgroundConfig, for: indexPath)
//                return background
//            }
//            return nil
//        }
        
        return nil 
    }
}
