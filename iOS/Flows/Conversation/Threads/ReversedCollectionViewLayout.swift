//
//  ReversedCollectionViewFlowLayout2.swift
//  ReversedCollectionViewFlowLayout2
//
//  Created by Martin Young on 10/21/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReversedCollectionViewLayout: UICollectionViewLayout {

    var cellLayoutAttributes: [[UICollectionViewLayoutAttributes]] = []

    override var collectionViewContentSize: CGSize {
        get {
            guard let collectionView = collectionView, collectionView.frame != .zero else { return .zero }

            let height: CGFloat
            if let firstSection = self.cellLayoutAttributes.first, let firstItem = firstSection.first {
                height = firstItem.frame.maxY
            } else {
                height = 0
            }

            return CGSize(width: collectionView.width, height: height)
        }
    }

    override func invalidateLayout() {
        super.invalidateLayout()

        self.cellLayoutAttributes = []
    }

    override func prepare() {
        guard let collectionView = collectionView else { return }

        let sectionCount = collectionView.numberOfSections

        self.cellLayoutAttributes = Array(repeating: [], count: sectionCount)

        for section in 0..<sectionCount {
            let itemCount = collectionView.numberOfItems(inSection: section)
            for item in 0..<itemCount {
                let indexPath = IndexPath(item: item, section: section)
                let layoutAttributes = self.layoutAttributesForItem(at: indexPath)
                self.cellLayoutAttributes[section].append(layoutAttributes!)
            }
        }
    }

    // MARK: - Layout calculations

    func rectForItem(at indexPath: IndexPath) -> CGRect {
        let origin = self.originForItemInSection(at: indexPath.item)
        let size = CGSize(width: 250, height: 120)

        return CGRect(origin: origin, size: size)
    }

    private func originForItemInSection(at index: Int) -> CGPoint {
        let y =  self.collectionView!.contentSize.height - CGFloat(1 + index * 120)
        return CGPoint(x: 0, y: y)
    }
}
