//
//  MembersCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class OrbCollectionViewLayout: UICollectionViewLayout {

    let interimSpace: CGFloat = 40.0
    let itemSize: CGFloat = 160
    var screenCenter: CGPoint {
        return CGPoint(x: UIScreen.main.bounds.width * 0.5,
                       y: UIScreen.main.bounds.height * 0.5)
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

    var a: CGFloat {
        return 2.5 * UIScreen.main.bounds.width
    }

    var b: CGFloat {
        return 2.5 * UIScreen.main.bounds.height
    }

    let c: CGFloat = 15

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = self.collectionView else { return .zero }

        let radius = self.getRadius(forIndexPath: IndexPath(item: self.cellCount - 1, section: 0))
        let width: CGFloat = radius.doubled + collectionView.halfWidth
        let height: CGFloat = radius.doubled + collectionView.halfHeight
        return CGSize(width: width, height: height)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = [UICollectionViewLayoutAttributes]()
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
        var x = centerPoint.x
        var y = centerPoint.y
        attributes.center = centerPoint

        let offset = self.collectionView!.contentOffset
        x -= self.screenCenter.x + CGFloat(offset.x)
        y -= self.screenCenter.y + CGFloat(offset.y)

        x = -x*x/(self.a * self.a)
        y = -y*y/(self.b * self.b)
        var z = self.c * (x+y) + 1.0
        z = z < 0.0 ? 0.0 : z

        attributes.transform = CGAffineTransform(scaleX: z, y: z)
        attributes.size = CGSize(width: self.itemSize, height: self.itemSize)

        return attributes
    }

    private func getCenter(forIndexPath indexPath: IndexPath) -> CGPoint {
        let center = CGPoint(x: self.collectionViewContentSize.width.half,
                             y: self.collectionViewContentSize.height.half)

        guard indexPath.row > 0 else { return center }

        var orbitIndex: Int = 0
        // The index of an item relative to the starting index of the orbit it is in
        var indexInOrbit: Int = 0
        // Because the first item is reserved for the center, start on index 1
        var currentOrbitStartIndex: Int = 1

        // Determine which orbit the item is in and the index of that item within its orbit
        while true {
            // The starting index of the next orbit.
            // We add 1 at the end because the first item is in the center, which shifts everything up 1
            let nextOrbitStartIndex = (pow(2, orbitIndex + 1) - 1) * self.firstOrbitItemCount + 1

            // Check to see if the index path is in the current orbit
            if indexPath.row < nextOrbitStartIndex {
                // If so calculate its index within the current orbit.
                indexInOrbit = indexPath.row - currentOrbitStartIndex
                break
            }

            orbitIndex += 1
            currentOrbitStartIndex = nextOrbitStartIndex
        }

        // The distance between the previous orbits center and the following orbits circumference
        let radius = (self.itemSize + self.interimSpace) * CGFloat(orbitIndex + 1)
        let totalInGivenOrbit = pow(2, orbitIndex) * self.firstOrbitItemCount
        // The angle between each item in the current orbit
        let angle = CGFloat(2 * Double.pi) / CGFloat(totalInGivenOrbit)
        let itemAngle = angle * CGFloat(indexInOrbit) // The actual angle of the item
        let itemX = (radius * cos(itemAngle)) + center.x
        let itemY = (radius * sin(itemAngle)) + center.y

        return CGPoint(x: itemX, y: itemY) // Used to set the center point of the current item
    }

    private func getRadius(forIndexPath indexPath: IndexPath) -> CGFloat {
        guard indexPath.row > 0 else { return 0 }

        var orbitRadius: Int = 0
        var orbitIndex: Int = 0

        while true {
            orbitIndex = 1 + self.firstOrbitItemCount * 2 * orbitRadius
            orbitRadius+=1
            if indexPath.row < orbitIndex  {
                break
            }
        }

        let radius = (self.itemSize + self.interimSpace) * CGFloat(orbitRadius)

        return radius
    }
}
