//
//  ReverseCollectionViewFlowLayout.swift
//  ReverseCollectionViewFlowLayout
//
//  Created by Martin Young on 10/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReversedCollectionViewFlowLayout: UICollectionViewFlowLayout {

    // MARK: - Overrides

    override var scrollDirection: UICollectionView.ScrollDirection {
        get { super.scrollDirection }
        set {
            if newValue == .horizontal { logDebug("Warning, horizontal scrolling is not supported!") }
            super.scrollDirection = newValue
        }
    }

    var previousContentSize: CGSize?

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if let previousContentSize = self.previousContentSize {
            if previousContentSize.height != self.collectionViewContentSize.height {
                return true
            }
        }

        self.previousContentSize = self.collectionViewContentSize
        return super.shouldInvalidateLayout(forBoundsChange: newBounds)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let reversedRect = self.reversedRect(forRect: rect)
        let attributes = super.layoutAttributesForElements(in: reversedRect)

        var result: [UICollectionViewLayoutAttributes] = []
        for attribute in attributes ?? [] {
            let newAttribute = attribute.copy() as! UICollectionViewLayoutAttributes
            self.reverseCenter(of: newAttribute)
            result.append(newAttribute)
        }
        return result
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath) else { return nil }

        let attributesCopy = attributes.copy() as! UICollectionViewLayoutAttributes
        self.reverseCenter(of: attributesCopy)
        return attributes
    }

    // MARK: - UICollectionViewLayoutAttributes transform

    private func reverseCenter(of attributes: UICollectionViewLayoutAttributes) {
        let originalCenter = attributes.center
        let reversedCenter = self.reversedPoint(forPoint: originalCenter)
        attributes.center = reversedCenter
    }

    // MARK: - Rect transform

    /// Returns the reversed-layout rect corresponding to the normal-layout rect
    private func reversedRect(forRect rect: CGRect) -> CGRect {
        let size = rect.size
        let normalTopLeft = rect.origin
        let reversedBottomLeft = self.reversedPoint(forPoint: normalTopLeft)
        let reversedTopLeft = CGPoint(x: reversedBottomLeft.x, y: reversedBottomLeft.y - size.height)
        let reversedRect = CGRect(x: reversedTopLeft.x,
                                  y: reversedTopLeft.y,
                                  width: size.width,
                                  height: size.height)
        return reversedRect
    }

    // MARK: - Point transform

    /// Returns the reversed-layout point corresponding to the normal-layout point
    private func reversedPoint(forPoint normalPoint: CGPoint) -> CGPoint {
        return CGPoint(x: normalPoint.x, y: self.reversedYForNormalY(normalPoint.y))
    }

    // MARK: - Y transform

    /// Returns the reversed-layout y-offset, corresponding the normal-layout y-offset
    private func reversedYForNormalY(_ normalY: CGFloat) -> CGFloat {
        let yReversedAroundContentSizeCenter = self.collectionViewContentSize.height - normalY
        return yReversedAroundContentSizeCenter
    }
}
