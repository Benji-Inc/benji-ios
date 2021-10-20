//
//  ReverseCollectionViewFlowLayout.swift
//  ReverseCollectionViewFlowLayout
//
//  Created by Martin Young on 10/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReversedCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override var scrollDirection: UICollectionView.ScrollDirection {
        get { super.scrollDirection }
        set {
            if newValue == .horizontal {
                logDebug("Warning, horizontal scrolling is not supported!")
            }
            super.scrollDirection = newValue
        }
    }

    override func prepare() {
        guard let collectionView = self.collectionView else { return }

        collectionView.contentInset = UIEdgeInsets(top: 0,
                                                   left: collectionView.width * 0.1,
                                                   bottom: 0,
                                                   right: collectionView.width * 0.1)

        let itemHeight: CGFloat = collectionView.height * 0.2

        self.itemSize = CGSize(width: collectionView.width * 0.8, height: itemHeight)

        // NOTE: Subtracting 1 to ensure there's enough vertical space for the cells.
        let verticalSpacing = (collectionView.height - itemHeight - 1)
        self.sectionInset = UIEdgeInsets(top: 0,
                                         left: 0,
                                         bottom: verticalSpacing,
                                         right: 0)
        self.minimumLineSpacing = collectionView.width * 0.05
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = self.collectionView else {
            return super.shouldInvalidateLayout(forBoundsChange: newBounds)
        }

        if fabsf(Float(collectionView.bounds.size.height - newBounds.size.height)) > Float.ulpOfOne {
            return true
        } else {
            return super.shouldInvalidateLayout(forBoundsChange: newBounds)
        }
    }

    override var collectionViewContentSize: CGSize {
        var expandedSize = super.collectionViewContentSize
        expandedSize.height = max(self.collectionView!.bounds.size.height, expandedSize.height)
        return expandedSize
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else {
            return super.layoutAttributesForItem(at: indexPath)
        }

        self.modifyLayoutAttributes(attributes)
        return attributes
    }

    override func layoutAttributesForElements(in reversedRect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let normalRect = self.normalRect(forReversedRect: reversedRect)
        let attributes = super.layoutAttributesForElements(in: normalRect)
        var result: [UICollectionViewLayoutAttributes] = []
        for attribute in attributes ?? [] {
            guard let attr = attribute.copy() as? UICollectionViewLayoutAttributes else {
                continue
            }
            self.modifyLayoutAttributes(attr)
            result.append(attr)
        }
        return result
    }

    //    #pragma mark - helpers

    func modifyLayoutAttributes(_ attributes: UICollectionViewLayoutAttributes) {
        let normalCenter = attributes.center
        let reversedCenter = self.reversedPointForNormalPoint(normalCenter)
        attributes.center = reversedCenter;
    }

    //    // rect transform

    /// Returns the reversed-layout rect corresponding to the normal-layout rect
    func reversedRect(forNormalRect normalRect: CGRect) -> CGRect {
        let size = normalRect.size
        let normalTopLeft = normalRect.origin
        let reversedBottomLeft = self.reversedPointForNormalPoint(normalTopLeft)
        let reversedTopLeft = CGPoint(x: reversedBottomLeft.x, y: reversedBottomLeft.y - size.height)
        let reversedRect = CGRect(x: reversedTopLeft.x, y: reversedTopLeft.y, width: size.width, height: size.height)
        return reversedRect
    }

    /// Returns the normal-layout rect corresponding to the reversed-layout rect
    func normalRect(forReversedRect reversedRect: CGRect) -> CGRect {
        // reflection is its own inverse
        return self.reversedRect(forNormalRect: reversedRect)
    }

    // point transforms

    /// Returns the reversed-layout point corresponding to the normal-layout point
    func reversedPointForNormalPoint(_ normalPoint: CGPoint) -> CGPoint {
        return CGPoint(x: normalPoint.x, y: self.reversedYforNormalY(normalPoint.y))
    }
    /// Returns the normal-layout point corresponding to the reversed-layout point
    func normalPoint(forReversedPoint reversedPoint: CGPoint) -> CGPoint {
        // reflection is its own inverse
        return self.reversedPointForNormalPoint(reversedPoint)
    }

    // y transforms

    /// Returns the reversed-layout y-offset, corresponding the normal-layout y-offset

    func reversedYforNormalY(_ normalY: CGFloat) -> CGFloat {
        let YreversedAroundContentSizeCenter = collectionViewContentSize.height - normalY
        return YreversedAroundContentSizeCenter
    }

    //    /// Returns the normal-layout y-offset, correspoding the reversed-layout y-offset
    func normalYforReversedY(_ reversedY: CGFloat) -> CGFloat {
        // reflection is its own inverse
        return reversedYforNormalY(reversedY)
    }

}
