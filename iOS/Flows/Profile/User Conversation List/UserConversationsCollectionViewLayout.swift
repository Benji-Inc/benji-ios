//
//  UserConversationsCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserConversationsCollectionViewLayout: UICollectionViewCompositionalLayout {

    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical

        super.init(sectionProvider: { sectionIndex, environment in
            guard let sectionType = UserConversationsDataSource.SectionType(rawValue: sectionIndex) else { return nil }

            switch sectionType {
            case .conversations:
                let sectionInset: CGFloat = Theme.ContentOffset.xtraLong.value

                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(140))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                             leading: sectionInset,
                                                             bottom: 0,
                                                             trailing: sectionInset)

                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                              leading: 0,
                                                              bottom: 0,
                                                              trailing: 0)

                // Section
                let section = NSCollectionLayoutSection(group: group)
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
