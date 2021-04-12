//
//  CommentsViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 4/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class CommentsViewController: CollectionViewController<CommentsCollectionViewManager.SectionType, CommentsCollectionViewManager> {

    private lazy var commentsCollectionView = CommentsCollectionView(layout: UICollectionViewFlowLayout())

    private let post: Post

    init(with post: Post) {
        self.post = post
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func getCollectionView() -> CollectionView {
        return self.commentsCollectionView
    }

    private func createComment(with body: String, replyId: String? = nil) {
        CreateComment(postId: self.post.objectId!,
                      body: body,
                      attributes: [:],
                      replyId: replyId)
            .makeRequest(andUpdate: [], viewsToIgnore: [])
            .mainSink { result in
                switch result {
                case .success(_):
                    break
                case .error(_):
                    break
                }
            }.store(in: &self.cancellables)
    }
}
