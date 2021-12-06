//
//  ColorPickerDiffableDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ColorPickerCollectionViewDataSource: CollectionViewDataSource<ColorPickerCollectionViewDataSource.SectionType, ColorPickerCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case colors
    }

    enum ItemType: Hashable {
        case color(CIColor)
        case wheel(CIColor?)
    }

    private let config = ManageableCellRegistration<ColorCell>().provider
    private let configWheel = ManageableCellRegistration<ColorWheelCell>().provider

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {
        switch item {
        case .color(let color):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: color)
        case .wheel(let color):
            return collectionView.dequeueConfiguredReusableCell(using: self.configWheel,
                                                                for: indexPath,
                                                                item: color)
        }
    }
}

