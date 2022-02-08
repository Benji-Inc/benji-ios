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
        case transactions
    }

    enum ItemType: Hashable {
        case transaction(Transaction)
    }

    private let transactionConfig = ManageableCellRegistration<TransactionCell>().provider
    private let headerConfig = ManageableHeaderRegistration<WalletHeaderView>().provider
    private let backgroundConfig = ManageableSupplementaryViewRegistration<BackgroundSupplementaryView>().provider
    private let segmentControlConfig = ManageableSupplementaryViewRegistration<TransactionSegmentControlView>().provider
        
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
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        
        switch section {
        case .wallet:
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            header.configure(with: self.itemIdentifiers(in: .transactions))
            return header
        case .transactions:
            if kind == BackgroundSupplementaryView.kind {
                let background = collectionView.dequeueConfiguredReusableSupplementary(using: self.backgroundConfig, for: indexPath)
                return background
            } else if kind == TransactionSegmentControlView.kind {
                let segmentControl = collectionView.dequeueConfiguredReusableSupplementary(using: self.segmentControlConfig, for: indexPath)
                return segmentControl
            }
        }
        
        return nil 
    }
}
