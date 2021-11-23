//
//  ConversationThreadCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ThreadCollectionViewLayout: BottomToTopColumnCollectionViewLayout {

    override class var layoutAttributesClass: AnyClass {
        return ConversationMessageCellLayoutAttributes.self
    }
    
    private var insertingIndexPaths: [IndexPath] = []

    override func prepare() {
        guard let collectionView = self.collectionView else { return }

        collectionView.contentInset = UIEdgeInsets(top: collectionView.contentInset.top,
                                                   left: collectionView.width * 0.1,
                                                   bottom: collectionView.contentInset.bottom,
                                                   right: collectionView.width * 0.1)

        self.defaultItemSize = CGSize(width: collectionView.width * 0.8, height: MessageContentView.maximumHeight)
        self.defaultHeaderSize = .zero
        self.defaultFooterSize = .zero
        self.defaultItemSpacing = collectionView.width * 0.05

        // Call prepare after setting the item size and spacing so the super call can use those values.
        super.prepare()
    }

    

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
