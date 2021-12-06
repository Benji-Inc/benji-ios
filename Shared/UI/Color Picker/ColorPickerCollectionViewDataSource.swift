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
    }

    var didSelectColorWheel: CompletionOptional = nil

    private let config = ManageableCellRegistration<ColorCell>().provider
    private let footerConfig = ManageableFooterRegistration<ColorWheelView>().provider

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
        }
    }

    override func dequeueSupplementaryView(with collectionView: UICollectionView, kind: String, section: SectionType, indexPath: IndexPath) -> UICollectionReusableView? {

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            return nil
        case UICollectionView.elementKindSectionFooter:
            let footer = collectionView.dequeueConfiguredReusableSupplementary(using: self.footerConfig, for: indexPath)

            footer.didSelect { [unowned self] in
                self.didSelectColorWheel?()
            }
            return footer
        default:
            break
        }

        return nil
    }

}

