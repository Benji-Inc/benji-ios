//
//  EmotionCircleCollectionViewLayout.swift
//  Jibber
//
//  Created by Martin Young on 4/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation


class EmotionCircleCollectionViewLayout: UICollectionViewLayout {

    // Physics
    private lazy var animator = UIDynamicAnimator(collectionViewLayout: self)
    private let collisionBehavior = UICollisionBehavior()
    private let itemBehavior = UIDynamicItemBehavior()
    private let noiseField = UIFieldBehavior.noiseField(smoothness: 1, animationSpeed: 0.01)

    private let cellDiameter: CGFloat = 100

    override init() {
        super.init()

        self.collisionBehavior.translatesReferenceBoundsIntoBoundary = true
        self.collisionBehavior.collisionMode = .boundaries
        self.animator.addBehavior(self.collisionBehavior)

        self.itemBehavior.elasticity = 1
        self.itemBehavior.friction = 0
        self.itemBehavior.resistance = 0
        self.itemBehavior.angularResistance = 0
        self.animator.addBehavior(self.itemBehavior)

        self.noiseField.strength = 10
        self.animator.addBehavior(self.noiseField)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var collectionViewContentSize: CGSize {
        return self.collectionView?.bounds.size ?? .zero
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = self.collectionView else { return false }

        return newBounds.size != collectionView.size
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.animator.items(in: rect).compactMap { item in
            return item as? UICollectionViewLayoutAttributes
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.animator.layoutAttributesForCell(at: indexPath)
    }

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)


        guard let collectionView = self.collectionView else { return }

        for updateItem in updateItems {
            switch updateItem.updateAction {
            case .insert:
                guard let indexPath = updateItem.indexPathAfterUpdate else { break }
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.size = CGSize(width: self.cellDiameter, height: self.cellDiameter)
                attributes.frame.origin
                = CGPoint(x: CGFloat.random(in: 0...collectionView.width - self.cellDiameter),
                          y: CGFloat.random(in: 0...collectionView.height - self.cellDiameter))

                self.collisionBehavior.addItem(attributes)
                self.itemBehavior.addItem(attributes)
                self.noiseField.addItem(attributes)
            case .delete:
                guard let indexPath = updateItem.indexPathBeforeUpdate,
                      let attributes = self.animator.layoutAttributesForCell(at: indexPath) else { break }

                self.collisionBehavior.removeItem(attributes)
                self.itemBehavior.removeItem(attributes)
                self.noiseField.removeItem(attributes)
            case .reload, .move, .none:
                break
            @unknown default:
                break
            }
        }
    }
}
