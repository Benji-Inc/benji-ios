//
//  EmotionCircleCollectionViewLayout.swift
//  Jibber
//
//  Created by Martin Young on 4/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol EmotionCircleCollectionViewLayoutDataSource: AnyObject {
    func getId(forItemAt indexPath: IndexPath) -> String
}

class EmotionCircleAttributes: UICollectionViewLayoutAttributes {

    var id = String()

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! EmotionCircleAttributes
        copy.id = self.id
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let layoutAttributes = object as? EmotionCircleAttributes {
            return super.isEqual(object)
            && layoutAttributes.id == self.id
        }

        return false
    }
}

class EmotionCircleCollectionViewLayout: UICollectionViewLayout {

    weak var dataSource: EmotionCircleCollectionViewLayoutDataSource!

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
        // The collection view is not scrollable.
        return self.collectionView?.bounds.size ?? .zero
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = self.collectionView else { return false }

        return newBounds.size != collectionView.frame.size
    }

    override func prepare() {
        super.prepare()

        guard let collectionView = self.collectionView else { return }

        // Get all of the emotion attributes being managed by the animator.
        let animatorAttributes
        = self.animator.items(in: collectionView.bounds).compactMap { item in
            return item as? EmotionCircleAttributes
        }

        // Keep track of the ids of items that currently exist in the data source.
        var foundIds = Set<String>()

        self.forEachIndexPath { indexPath in
            // Get the id of the attributes and save it for later use.
            let id = self.dataSource.getId(forItemAt: indexPath)

            foundIds.insert(id)
            // Check to see if the attribute already exists in the animator
            if let matchingAttributes = animatorAttributes.first(where: { attributes in
                return attributes.id == id
            }) {
                // The attributes were already added, but update the index path in case
                // it's no longer valid due to inserts/deletes.
                matchingAttributes.indexPath = indexPath
            } else {
                // The item's attributes aren't yet being managed by the animator. Add them now.
                self.addEmotionAttributesToAnimator(for: indexPath, withId: id)
            }
        }

        // Removing any attributes from the animator that no longer exists.
        animatorAttributes.forEach { attributes in
            guard !foundIds.contains(attributes.id) else { return }
            self.removeDynamicItemFromAnimator(attributes)
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.animator.items(in: rect).compactMap { item in
            return item as? UICollectionViewLayoutAttributes
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.animator.layoutAttributesForCell(at: indexPath)
    }

    // MARK: - Animator Functions

    
    private func addEmotionAttributesToAnimator(for indexPath: IndexPath, withId id: String) {
        guard let collectionView = self.collectionView else { return }

        let attributes = EmotionCircleAttributes(forCellWith: indexPath)
        attributes.id = id

        let clampedDiameter = clamp(self.cellDiameter,
                                    0,
                                    min(collectionView.width, collectionView.height))
        attributes.size = CGSize(width: clampedDiameter, height: clampedDiameter)
        attributes.frame.origin
        = CGPoint(x: CGFloat.random(in: 0...collectionView.width - clampedDiameter),
                  y: CGFloat.random(in: 0...collectionView.height - clampedDiameter))

        // Give the cell a little push to get them moving.
        let pushBehavior = UIPushBehavior(items: [attributes], mode: .instantaneous)
        pushBehavior.setAngle(CGFloat.random(in: 0...CGFloat.pi*2), magnitude: 0.2)
        pushBehavior.action = { [unowned self, unowned pushBehavior] in
            // Clean up the push after it's done
            guard !pushBehavior.active else { return }
            self.animator.removeBehavior(pushBehavior)
        }
        self.animator.addBehavior(pushBehavior)

        self.collisionBehavior.addItem(attributes)
        self.itemBehavior.addItem(attributes)
        self.noiseField.addItem(attributes)
    }

    private func removeDynamicItemFromAnimator(_ item: UIDynamicItem) {
        self.collisionBehavior.removeItem(item)
        self.itemBehavior.removeItem(item)
        self.noiseField.removeItem(item)
    }
}

extension EmotionCircleCollectionViewLayout {

    /// Runs the passed in closure on every valid index path in the collection view.
    private func forEachIndexPath(_ apply: (IndexPath) -> Void) {
        let sectionCount = self.collectionView!.numberOfSections
        for section in 0..<sectionCount {
            let itemCount = self.collectionView!.numberOfItems(inSection: section)
            for item in 0..<itemCount {
                let indexPath = IndexPath(item: item, section: section)
                apply(indexPath)
            }
        }
    }
}
