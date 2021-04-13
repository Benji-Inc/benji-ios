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

    // Custom Input Accessory View
    lazy var commentInputAccessoryView = CommentInputAccessoryView()

    override var inputAccessoryView: UIView? {
        return self.commentInputAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.resignFirstResponder()
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.insertSubview(self.imageView, at: 0)
        self.imageView.contentMode = .scaleAspectFill

        KeyboardManger.shared.inputAccessoryView = self.inputAccessoryView

        KeyboardManger.shared.$isKeyboardShowing.mainSink { isShowing in
            if isShowing {
                self.didPause?()
            } else {
                self.didResume?()
            }
        }.store(in: &self.cancellables)

        //self.button.set(style: .normal(color: .purple, text: "Comment"))
    }

    override func getBottomContent() -> UIView? {
        return nil
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
