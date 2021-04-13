//
//  PostMediaViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PostMediaViewController: PostViewController {

    private let imageView = UIImageView()
    private lazy var commentsVC = CommentsViewController(with: self.post)

    override func initializeViews() {
        super.initializeViews()

        self.view.insertSubview(self.imageView, at: 0)
        self.imageView.contentMode = .scaleAspectFill

        self.button.set(style: .normal(color: .purple, text: "Comment"))
    }

    override func didTapButton() {
        self.didPause?()
        self.addChild(viewController: self.commentsVC)
        self.view.alpha = 0.5
        self.view.layoutNow()
        self.commentsVC.collectionViewManager.loadComments()
    }

    override func configurePost() {
        super.configurePost()

        guard let file = self.post.file else { return }

        file.getDataInBackground { data, error in
            if let data = data, let image = UIImage(data: data) {
                self.imageView.image = image
            }
        } progressBlock: { progress in
            print(progress)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.imageView.expandToSuperviewSize()
        self.commentsVC.view.expandToSuperviewSize()
    }
}
