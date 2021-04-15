//
//  CommentsCollectionView.swift
//  Ours
//
//  Created by Benji Dodgson on 4/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CommentsCollectionView: CollectionView {

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        super.init(layout: layout)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func scrollToEnd(animated: Bool = true, completion: CompletionOptional = nil) {

        let section = self.numberOfSections - 1
        let item = self.numberOfItems(inSection: section) - 1
        let lastIndexPath = IndexPath(item: item, section: section)
        self.scrollToItem(at: lastIndexPath, at: .bottom, animated: animated)

        completion?()
    }
}
