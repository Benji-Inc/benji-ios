//
//  UICollectionView+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

extension UICollectionView {

    func performBatchUpdates(modifyItems: (() -> Swift.Void)? = nil,
                             updates: (() -> Swift.Void)? = nil,
                             completion: ((Bool) -> Swift.Void)? = nil) {

        if self.frame == .zero {
            modifyItems?()
            self.reloadData()
            completion?(true)
            return
        }

        self.performBatchUpdates({
            modifyItems?()
            updates?()
        }, completion: { (completed) in
            // Force collection view to update otherwise the cells will reflect the old layout
            self.collectionViewLayout.invalidateLayout()
            completion?(completed)
        })
    }
}
