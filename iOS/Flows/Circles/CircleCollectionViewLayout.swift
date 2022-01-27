//
//  CircleCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleCollectionViewLayout: UICollectionViewLayout {
    
    // MARK: Getting the Collection View Information
    
    override var collectionViewContentSize: CGSize {
        return collectionView?.bounds.size ?? .zero
    }
    
    // MARK: Invalidating the Layout
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return false
    }
    
    // MARK: Providing Layout Attributes
    
    private var layoutCircleFrame = CGRect.zero
    private let layoutInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    private let itemSize = CGSize(width: 100, height: 100)
    private var itemLayoutAttributes = [UICollectionViewLayoutAttributes]()
    
    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }
        
        self.itemLayoutAttributes.removeAll()
        self.layoutCircleFrame = CGRect(origin: .zero, size: collectionViewContentSize)
            .inset(by: layoutInsets)
            .insetBy(dx: itemSize.width / 2.0, dy: itemSize.height / 2.0)
            .offsetBy(dx: collectionView.contentOffset.x, dy: collectionView.contentOffset.y - 50)
            .insetBy(dx: -collectionView.contentOffset.x, dy: -collectionView.contentOffset.y)
        
        for section in 0..<collectionView.numberOfSections {
            switch section {
            case 0:
                let itemCount = collectionView.numberOfItems(inSection: section)
                self.itemLayoutAttributes = (0..<itemCount).map({ (index) -> UICollectionViewLayoutAttributes in
                    let angleStep: CGFloat = 2.0 * CGFloat.pi / CGFloat(itemCount)
                    var position = self.layoutCircleFrame.center
                    position.x += self.layoutCircleFrame.size.innerRadius * cos(angleStep * CGFloat(index))
                    position.y += self.layoutCircleFrame.size.innerRadius * sin(angleStep * CGFloat(index))
                    let indexPath = IndexPath(item: index, section: section)
                    let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                    attributes.frame = CGRect(center: position, size: itemSize)
                    return attributes
                })
            default:
                fatalError("Unhandled section \(section).")
            }
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.itemLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let numberOfItems = collectionView?.numberOfItems(inSection: indexPath.section) ?? 0
        guard numberOfItems > 0 else { return nil }
        switch indexPath.section {
        case 0:
            return self.itemLayoutAttributes[indexPath.item]
        default:
            fatalError("Unknown section \(indexPath.section).")
        }
    }
}

extension CGRect {
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - size.width / 2.0, y: center.y - size.height / 2.0, width: size.width, height: size.height)
    }
}

extension CGSize {
    var innerRadius: CGFloat { return min(width, height) / 2.0 }
}
