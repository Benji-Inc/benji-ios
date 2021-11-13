//
//  InputTypeCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/11/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InputTypeDataSource: CollectionViewDataSource<InputTypeDataSource.SectionType, InputType> {

    enum SectionType: Int, CaseIterable {
        case types
    }

    private let inputConfig = ManageableCellRegistration<InputTypeCell>().provider

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: InputType) -> UICollectionViewCell? {
        
        return collectionView.dequeueConfiguredReusableCell(using: self.inputConfig, for: indexPath, item: item)
    }
}
