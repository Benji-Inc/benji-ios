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

    lazy var commentsCollectionView = CommentsCollectionView()
    private let exitButton = ImageViewButton()
    var didTapExit: CompletionOptional = nil

    private let post: Postable

    init(with post: Postable) {
        self.post = post
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        if let post = self.post as? Post {
            self.collectionViewManager.post = post 
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.insertSubview(self.exitButton, aboveSubview: self.collectionViewManager.collectionView)
        self.exitButton.imageView.image = UIImage(systemName: "xmark")!
        self.exitButton.didSelect { [unowned self] in
            self.didTapExit?()
        }
    }

    override func getCollectionView() -> CollectionView {
        return self.commentsCollectionView
    }

    func createComment(with object: Sendable, post: Post) {

        let systemComment = SystemComment(with: post, object: object)

        self.collectionViewManager.comments.append(systemComment)
        self.commentsCollectionView.scrollToEnd()

        CreateComment(comment: systemComment)
            .makeRequest(andUpdate: [], viewsToIgnore: [])
            .mainSink { result in
                switch result {
                case .success(_):
                    break 
                case .error(let error):
                    print(error)
                }
            }.store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.exitButton.squaredSize = 50
        self.exitButton.pin(.top, padding: Theme.contentOffset)
        self.exitButton.pin(.right, padding: Theme.contentOffset)
    }
}
