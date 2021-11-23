//
//  ConversationThreadCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ThreadCollectionViewLayout: TimelineCollectionViewLayout {
    
    private var insertingIndexPaths: [IndexPath] = []

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)

        self.insertingIndexPaths.removeAll()

        for update in updateItems {
            if let indexPath = update.indexPathAfterUpdate,
                update.updateAction == .insert {
                self.insertingIndexPaths.append(indexPath)
            }
        }
    }

    override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()

        self.insertingIndexPaths.removeAll()
    }

    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath)
    -> UICollectionViewLayoutAttributes? {

        let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)

        if self.insertingIndexPaths.contains(itemIndexPath) {
            attributes?.alpha = 0.0
            attributes?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }

        return attributes
    }
}
