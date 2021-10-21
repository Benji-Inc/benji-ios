//
//  ConversationThreadCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationThreadCollectionViewLayout: ReversedCollectionViewFlowLayout {

    override class var layoutAttributesClass: AnyClass {
        return ConversationCollectionViewLayoutAttributes.self
    }
    
    private var insertingIndexPaths: [IndexPath] = []

    override init() {
        super.init()

        self.scrollDirection = .vertical
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()

        guard let collectionView = self.collectionView else { return }

        collectionView.contentInset = UIEdgeInsets(top: 0,
                                                   left: collectionView.width * 0.1,
                                                   bottom: 0,
                                                   right: collectionView.width * 0.1)

        self.itemSize = CGSize(width: collectionView.width * 0.8, height: 120)
        self.minimumLineSpacing = collectionView.width * 0.05
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
