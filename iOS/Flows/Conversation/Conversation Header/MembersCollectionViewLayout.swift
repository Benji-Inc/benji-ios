//
//  MembersCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MembersCollectionViewLayout: UICollectionViewCompositionalLayout {
    
    override class var layoutAttributesClass: AnyClass {
        return MemberCellLayoutAttributes.self
    }

    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal

        super.init(sectionProvider: { sectionIndex, environment in
            guard let sectionType = MembersCollectionViewDataSource.SectionType(rawValue: sectionIndex) else { return nil }

            switch sectionType {
            case .members:
                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.14), heightDimension: .fractionalHeight(1))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: environment.container.contentSize.width.half, bottom: 0, trailing: environment.container.contentSize.width.half)
                return section
            }

        }, configuration: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) as? [MemberCellLayoutAttributes] else {
            return nil
        }
        return attributes.map({ attribute in
            let copy = attribute.copy() as! MemberCellLayoutAttributes
            return self.transformLayoutAttributes(copy)
        })
    }

    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath) as? MemberCellLayoutAttributes else {
            return nil
        }
        let copy = attributes.copy() as! MemberCellLayoutAttributes
        return self.transformLayoutAttributes(copy)
    }

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath) else {
            return nil
        }
        let copy = attributes.copy() as! MemberCellLayoutAttributes
        return self.transformLayoutAttributes(copy)
    }

    private func transformLayoutAttributes(_ attributes: MemberCellLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let collectionView = self.collectionView else { return attributes }

        let size = attributes.size
        attributes.size = CGSize(width: size.height, height: size.height)
        let contentWidth = collectionView.width - collectionView.contentInset.left - collectionView.contentInset.right
        let distanceFromCenter = abs((attributes.frame.centerX - collectionView.contentOffset.x) - contentWidth.half)
        let minScale: CGFloat = 0.75
        let maxScale: CGFloat = 1.0
        let scale = max(maxScale - (distanceFromCenter / contentWidth), minScale)
        let transfrom = CGAffineTransform(scaleX: scale, y: scale)
        attributes.transform = transfrom
        let centerY: CGFloat = (size.height * scale).half
        attributes.center = CGPoint(x: attributes.center.x, y: centerY)

        return attributes
    }
}
