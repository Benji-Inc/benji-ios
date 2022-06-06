//
//  CommonExpressionsDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CommonExpressionsDataSource: CollectionViewDataSource<CommonExpressionsDataSource.SectionType,
                                   CommonExpressionsDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case expressions
    }

    enum ItemType: Hashable {
        case expression(ExpressionModel)
    }

    private let config = ManageableCellRegistration<ExpressionCell>().provider
    
    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .expression(let model):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: model)
        }
    }
}
