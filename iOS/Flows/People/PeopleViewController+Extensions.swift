//
//  PeopleViewController+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/24/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension PeopleViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return }
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewManagerCell {
            cell.update(isSelected: true )
        }
        self.delegate?.peopleView(self, didSelect: identifier)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewManagerCell {
            cell.update(isSelected: false)
        }
    }
}
