//
//  MembersCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class OrbCollectionViewLayout: UICollectionViewLayout {

    let interimSpace: CGFloat = 160
    let itemSize: CGFloat = 160
    var collectionViewCenter: CGPoint {
        guard let collectionView = self.collectionView else { return .zero }
        return CGPoint(x: collectionView.contentOffset.x + collectionView.halfWidth,
                       y: collectionView.contentOffset.y + collectionView.halfHeight)
    }

    var firstOrbitItemCount: Int = 6 {
        didSet {
            self.invalidateLayout()
        }
    }
    
    var cellCount: Int {
        guard let sections = self.collectionView?.numberOfSections, sections > 0 else { return 0 }
        return self.collectionView?.numberOfItems(inSection: 0) ?? 0
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    private var itemPositions: [CGPoint] = []

    override var collectionViewContentSize: CGSize {
        guard let collectionView = self.collectionView else { return .zero }
        return CGSize(width: collectionView.width.doubled, height: collectionView.height.doubled)
    }

    override func prepare() {
        super.prepare()

        self.itemPositions.removeAll()

        let centerPoint = CGPoint(x: self.collectionViewContentSize.width.half,
                                  y: self.collectionViewContentSize.height.half)

        var ringIndex: Int = 0

        // Generate points that describe the rings of this layout.
        while self.itemPositions.count < self.cellCount {
            // The number of items the current ring can hold.
            let ringItemCount: Int
            if ringIndex == 0 {
                // The first "ring" isn't truly a ring. It's just a point in the center so make a special case.
                ringItemCount = 1
            } else {
                ringItemCount = (ringIndex - 1) * self.firstOrbitItemCount + self.firstOrbitItemCount
            }

            // Generate the path for the current ring
            let ringPath = self.getRingPath(centerPoint: centerPoint,
                                            radius: CGFloat(ringIndex) * self.interimSpace,
                                            n: self.firstOrbitItemCount)

            // How far we've progressed along the current ring path.
            var currentNormalized: CGFloat = 0
            // How much to move along the path to place the get the next point.
            let ringNormalizedSegment: CGFloat = 1/CGFloat(ringItemCount)

            for _ in 0..<ringItemCount {
                let position = lerp(currentNormalized, keyPoints: ringPath)
                self.itemPositions.append(position)

                currentNormalized += ringNormalizedSegment
            }

            ringIndex += 1
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes: [UICollectionViewLayoutAttributes] = []
        for i in 0 ..< self.cellCount {
            let indexPath = IndexPath(item: i, section: 0)
            if let attributesForItem = self.layoutAttributesForItem(at: indexPath) {
                attributes.append(attributesForItem)
            }
        }
        return attributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        let centerPoint = self.getCenter(forIndexPath: indexPath)
        attributes.center = centerPoint
        attributes.size = CGSize(width: self.itemSize, height: self.itemSize)

        // Shrink the size of cells that aren't centered.
        let distanceFromCenter = centerPoint.distanceTo(self.collectionViewCenter)
        let scale = lerpClamped(distanceFromCenter/self.interimSpace,
                                start: 1,
                                end: 0.5)
        attributes.transform = CGAffineTransform(scaleX: scale, y: scale)

        return attributes
    }

    // MARK: - Helper Functions

    private func getCenter(forIndexPath indexPath: IndexPath) -> CGPoint {
        return self.itemPositions[indexPath.item]
    }

    /// Gets a set a points representing the path for a ring centered around a point.
    private func getRingPath(centerPoint point: CGPoint, radius: CGFloat, n: Int) -> [CGPoint] {
        let angles = stride(from: 0, to: twoPi, by: twoPi/CGFloat(n))

        var points: [CGPoint] = angles.map { angle in
            let x = point.x + radius * cos(angle)
            let y = point.y + radius * sin(angle)
            return CGPoint(x: x, y: y)
        }

        if let firstPoint = points.first {
            points.append(firstPoint)
        }

        return points
    }
}
