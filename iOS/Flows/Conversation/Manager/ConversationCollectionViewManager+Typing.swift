//
//  ConversationCollectionViewManager+Typing.swift
//  Benji
//
//  Created by Benji Dodgson on 11/11/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension ConversationCollectionViewManager {

    func isLastMessageVisible() -> Bool {
        let sectionCount = self.numberOfSections()

        guard sectionCount > 0, let sectionValue = self.sections.last else { return false }

        let lastIndexPath = IndexPath(item: sectionValue.items.count - 1, section: sectionCount - 1)
        return self.collectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
}
