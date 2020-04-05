//
//  InviteableCollectionViewManger.swift
//  Benji
//
//  Created by Benji Dodgson on 4/4/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InviteableCollectionViewManger: CollectionViewManager<InviteableCell> {

    private let selectionImpact = UIImpactFeedbackGenerator(style: .light)

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = self.items.value[safe: indexPath.row], case Inviteable.contact(_) = item else { return }

        super.collectionView(collectionView, didSelectItemAt: indexPath)

        self.selectionImpact.impactOccurred()
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 layout collectionViewLayout: UICollectionViewLayout,
                                 sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.width, height: 90)
    }
}
