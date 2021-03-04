//
//  CollectionViewManger+Snapshot.swift
//  Ours
//
//  Created by Benji Dodgson on 2/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension CollectionViewManager {

    func updateUI(animate: Bool) {
        let snapShot = self.createSnapshot()
        self.dataSource.apply(snapShot, animatingDifferences: animate, completion: nil)
    }
}
