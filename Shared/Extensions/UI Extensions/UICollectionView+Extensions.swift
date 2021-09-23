//
//  UICollectionView+Extensions.swift
//  UICollectionView+Extensions
//
//  Created by Martin Young on 8/24/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension UICollectionView {

    /// Returns the indexpath of the item whose cell is closest to the center of this collectionview. If there are no items visible, then nil is returned.
    func getCentermostVisibleIndex() -> IndexPath? {
        let visibleCells = self.visibleCells

        let centerPoint = CGPoint(x: self.contentOffset.x + self.centerX,
                                  y: self.contentOffset.y + self.centerY)
        var closestCell: UICollectionViewCell? = nil
        var lowestDistanceToCenter: CGFloat = .greatestFiniteMagnitude

        for visibleCell in visibleCells {
            let centerOfCell = visibleCell.center
            let distanceToCenter = centerPoint.distanceTo(centerOfCell)

            if closestCell.isNil {
                lowestDistanceToCenter = distanceToCenter
                closestCell = visibleCell
                continue
            }

            if distanceToCenter < lowestDistanceToCenter {
                lowestDistanceToCenter = distanceToCenter
                closestCell = visibleCell
            }
        }

        if let closestCell = closestCell {
            return self.indexPath(for: closestCell)
        }

        return nil
    }

    @MainActor
    func animateOut(position: AnimationPosition, concatenate: Bool) async {
        let visibleCells = self.visibleCells

        guard visibleCells.count > 0 else {
            self.alpha = 0
            return
        }

        let duration: TimeInterval = Theme.animationDuration
        var longestDelay: TimeInterval = 0

        for (index, cell) in visibleCells.enumerated() {
            cell.alpha = 1.0
            let delay: TimeInterval = concatenate ? duration/Double(visibleCells.count)*Double(index) : 0
            UIView.animate(withDuration: duration,
                           delay: delay,
                           options: .curveEaseInOut,
                           animations: {
                
                cell.transform = position.getTransform(for: cell)
                cell.alpha = 0.0
            })
            longestDelay = delay
        }

        // Wait for all of the cell animations to finish
        await Task.sleep(seconds: duration + longestDelay)

        self.alpha = 0
    }

    @MainActor
    func animateIn(position: AnimationPosition, concatenate: Bool) async {
        let visibleCells = self.visibleCells

        guard visibleCells.count > 0 else {
            self.alpha = 1
            return
        }

        let duration: TimeInterval = Theme.animationDuration
        var longestDelay: TimeInterval = 0

        for (index, cell) in visibleCells.enumerated() {
            cell.alpha = 0.0
            cell.transform = position.getTransform(for: cell)
            self.alpha = 1
            let delay: TimeInterval = concatenate ? duration/Double(visibleCells.count)*Double(index) : 0
            UIView.animate(withDuration: duration, delay: delay, options: .curveEaseInOut, animations: {
                cell.transform = .identity
                cell.alpha = 1.0
            })
            longestDelay = delay
        }

        // Wait for all of the cell animations to finish
        await Task.sleep(seconds: duration + longestDelay)
    }
}
