//
//  CommentsViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 4/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CommentsViewController: CollectionViewController<CommentsCollectionViewManager.SectionType, CommentsCollectionViewManager> {

    private lazy var commentsCollectionView = CommentsCollectionView(layout: UICollectionViewFlowLayout())

    override func getCollectionView() -> CollectionView {
        return self.commentsCollectionView
    }
}
