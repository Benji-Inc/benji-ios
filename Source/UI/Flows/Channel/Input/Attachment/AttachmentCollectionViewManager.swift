//
//  AttachentCollectionViewManager.swift
//  Benji
//
//  Created by Benji Dodgson on 8/29/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AttachmentCollectionViewManager: CollectionViewManager<AttachementCell> {

    override func collectionView(_ collectionView: UICollectionView,
                                 layout collectionViewLayout: UICollectionViewLayout,
                                 sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.contentSize.width * 0.33, height: collectionView.contentSize.height * 0.5)
    }

    // Add header
}
