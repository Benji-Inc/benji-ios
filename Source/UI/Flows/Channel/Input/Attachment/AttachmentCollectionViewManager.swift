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
        let width = collectionView.width * 0.3
        let height = collectionView.height * 0.5
        return CGSize(width: width, height: height)
    }

    // Add header
}
