//
//  EmotionCircleCollectionViewLayout.swift
//  Jibber
//
//  Created by Martin Young on 4/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

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

    // MARK: - UIDynamic Item

    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        return .ellipse
    }
}

class EmotionCircleCollectionViewLayout: UICollectionViewLayout {

    weak var dataSource: EmotionCircleCollectionViewLayoutDataSource!

    // Physics
    private lazy var animator = UIDynamicAnimator(collectionViewLayout: self)
    private var collisionBehavior: UICollisionBehavior!
    private var itemBehavior: UIDynamicItemBehavior!
    private var noiseField: UIFieldBehavior!

    private let cellDiameter: CGFloat

    init(cellDiameter: CGFloat) {
        self.cellDiameter = cellDiameter
        
        super.init()

        self.initializeBehaviors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Removes all existing behaviors from the animator, creates new ones, and then sets their initial parameters.
    private func initializeBehaviors() {
        self.animator.removeAllBehaviors()

        self.collisionBehavior = UICollisionBehavior()
        self.collisionBehavior.translatesReferenceBoundsIntoBoundary = true
        self.collisionBehavior.collisionMode = .boundaries
        self.collisionBehavior.collisionDelegate = self
        self.animator.addBehavior(self.collisionBehavior)

        self.itemBehavior = UIDynamicItemBehavior()
        self.itemBehavior.elasticity = 1
        self.itemBehavior.friction = 0
        self.itemBehavior.resistance = 0
        self.itemBehavior.angularResistance = 0
        self.animator.addBehavior(self.itemBehavior)

        self.noiseField = UIFieldBehavior.noiseField(smoothness: 0.2, animationSpeed: 1)
        self.noiseField.strength = 0.1
        self.animator.addBehavior(self.noiseField)
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

        let preexistingAttributes: [EmotionCircleAttributes]
        = self.animator.dynamicItems(in: collectionView.bounds)

        self.resetBehaviorsIfNeeded()

        // Get all of the emotion attributes being managed by the animator.
        // HACK: Due to an Apple bug, collision behaviors are incorrectly added to the items array,
        // which causes a crash when we try to access the items.
        // https://stackoverflow.com/questions/45774897/uidynamicanimator-itemsin-crashes-in-ios-11
        let animatorAttributes: [EmotionCircleAttributes]
        = self.animator.dynamicItems(in: collectionView.bounds)

        for indexPath in self.allIndexPaths {
            // Get the id of the attributes and save it for later use.
            let id = self.dataSource.getId(forItemAt: indexPath)

            // Check to see if the attributes already exist in the animator
            if !animatorAttributes.contains(where: { attributes in
                return attributes.id == id
            }) {

                if let preexistingAttribute = preexistingAttributes.first(where: { attributes in
                    return attributes.id == id
                }) {
                    let attributes = EmotionCircleAttributes(forCellWith: indexPath)
                    attributes.id = id
                    attributes.bounds = preexistingAttribute.bounds
                    attributes.center = preexistingAttribute.center
                    attributes.transform = preexistingAttribute.transform

                    self.collisionBehavior.addItem(attributes)
                    self.itemBehavior.addItem(attributes)
                    self.noiseField.addItem(attributes)
                } else {
                    // The item's attributes aren't yet being managed by the animator. Add them now.
                    self.addEmotionAttributesToAnimator(for: indexPath, withId: id, addPush: true)
                }
            }
        }
    }

    var previousIndexPaths: [IndexPath] = []
    var previousIds: [String] = []
    /// Resets the animator behaviors if any change has been made to the data source.
    func resetBehaviorsIfNeeded() {
        let currentIndexPaths: [IndexPath] = self.allIndexPaths
        var currentIds: [String] = []

        for indexPath in currentIndexPaths {
            let id = self.dataSource.getId(forItemAt: indexPath)
            currentIds.append(id)
        }

        // If there's any change to the data we need to reset the behaviors.
        if currentIndexPaths != self.previousIndexPaths || currentIds != self.previousIds {
            self.previousIndexPaths = currentIndexPaths
            self.previousIds = currentIds

            self.initializeBehaviors()
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.animator.dynamicItems(in: rect)
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.animator.layoutAttributesForCell(at: indexPath)
    }

    // MARK: - Animator Functions
    
    private func addEmotionAttributesToAnimator(for indexPath: IndexPath, withId id: String, addPush: Bool) {
        guard let collectionView = self.collectionView,
              collectionView.width > 0, collectionView.height > 0 else { return }

        let attributes = EmotionCircleAttributes(forCellWith: indexPath)
        attributes.id = id

        let clampedDiameter = clamp(self.cellDiameter,
                                    0,
                                    min(collectionView.width, collectionView.height))
        attributes.size = CGSize(width: clampedDiameter, height: clampedDiameter)
        attributes.frame.origin
        = CGPoint(x: CGFloat.random(in: 0...collectionView.width - clampedDiameter),
                  y: CGFloat.random(in: 0...collectionView.height - clampedDiameter))


        if addPush {
            // Give the cell a little push to get them moving.
            let pushBehavior = UIPushBehavior(items: [attributes], mode: .instantaneous)
            pushBehavior.setAngle(CGFloat.random(in: 0...CGFloat.pi*2), magnitude: 0.3)
            pushBehavior.action = { [unowned self, unowned pushBehavior] in
                // Clean up the push after it's done
                guard !pushBehavior.active else { return }
                self.animator.removeBehavior(pushBehavior)
            }
            self.animator.addBehavior(pushBehavior)
        }

        self.collisionBehavior.addItem(attributes)
        self.itemBehavior.addItem(attributes)
        self.noiseField.addItem(attributes)
    }
}

extension EmotionCircleCollectionViewLayout: UICollisionBehaviorDelegate {

    func collisionBehavior(_ behavior: UICollisionBehavior,
                           beganContactFor item: UIDynamicItem,
                           withBoundaryIdentifier identifier: NSCopying?,
                           at p: CGPoint) {

        let vector = CGVector(dx: item.center.x - p.x, dy: item.center.y - p.y)
        let pushBehavior = UIPushBehavior(items: [item], mode: .instantaneous)
        pushBehavior.pushDirection = vector
        pushBehavior.magnitude = 0.05
        pushBehavior.action = { [unowned self, unowned pushBehavior] in
            // Clean up the push after it's done
            guard !pushBehavior.active else { return }
            self.animator.removeBehavior(pushBehavior)
        }

        self.animator.addBehavior(pushBehavior)
    }
}

extension EmotionCircleCollectionViewLayout {

    /// Returns the index paths for all items managed by the collectionview.
    var allIndexPaths: [IndexPath] {
        var indexPaths: [IndexPath] = []

        let sectionCount = self.collectionView!.numberOfSections
        for section in 0..<sectionCount {
            let itemCount = self.collectionView!.numberOfItems(inSection: section)
            for item in 0..<itemCount {
                indexPaths.append(IndexPath(item: item, section: section))
            }
        }

        return indexPaths
    }
}


fileprivate extension UIDynamicAnimator {

    // HACK: This function is only needed due to an Apple bug.
    // Collision behaviors are incorrectly added to the items array.
    // https://stackoverflow.com/questions/45774897/uidynamicanimator-itemsin-crashes-in-ios-11
    func dynamicItems<ItemType: UIDynamicItem>(in rect: CGRect) -> [ItemType] {
        let nsItems = self.items(in: rect) as NSArray
        return nsItems.compactMap { item in
            return item as? ItemType
        }
    }
}
