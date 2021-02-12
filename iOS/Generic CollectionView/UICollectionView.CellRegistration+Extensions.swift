//
//  UICollectionView.CellRegistration+Extensions.swift
//  Ours
//
//  Created by Benji Dodgson on 2/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension UICollectionView.CellRegistration where Cell: CollectionViewManagerCell & ManageableCell {
    var cellProvider: (UICollectionView, IndexPath, Item) -> Cell {
        return { collectionView, indexPath, item in
            let cell = collectionView.dequeueConfiguredReusableCell(using: self,
                                                                    for: indexPath,
                                                                    item: item)
            if let foo = item as? Cell.ItemType {
                cell.configure(with: foo)
            }

            return cell
        }
    }
}
