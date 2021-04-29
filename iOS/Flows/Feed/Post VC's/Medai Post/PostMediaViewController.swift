//
//  PostMediaViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PostMediaViewController: PostViewController, CollectionViewInputHandler {

    var collectionView: CollectionView {
        return self.commentsVC.collectionViewManager.collectionView
    }

    var inputTextView: InputTextView {
        return self.commentInputAccessoryView.textView
    }

    var collectionViewBottomInset: CGFloat = 0 {
        didSet {
            self.collectionView.contentInset.bottom = self.collectionViewBottomInset
            self.collectionView.verticalScrollIndicatorInsets.bottom = self.collectionViewBottomInset
        }
    }

    var indexPathForEditing: IndexPath?

    private let imageView = UIImageView()
    private let gradientView = GradientView(with: [Color.clear.color.cgColor, Color.background1.color.withAlphaComponent(0.5).cgColor], startPoint: .topCenter, endPoint: .bottomCenter)
    private let captionView = CaptionView()
    private lazy var commentsVC = CommentsViewController(with: self.post)
    private let consumersView = StackedAvatarView()
    private let commentsButton = CommentsButton()
    private let moreButton = MediaMoreButton()

    // Custom Input Accessory View
    lazy var commentInputAccessoryView = CommentInputAccessoryView(with: self)

    var isShowingComments: Bool = false

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

        self.view.set(backgroundColor: .background1)

        guard let post = self.post as? Post else { return }

        post.consumers?.query().findObjectsInBackground(block: { objects, error in
            if let users = objects {
                self.consumersView.set(items: users)
                self.view.layoutNow()
            }
        })

        self.view.insertSubview(self.imageView, at: 0)
        self.imageView.contentMode = .scaleAspectFill

        self.view.addSubview(self.gradientView)

        self.view.addSubview(self.captionView)
        self.captionView.setText(for: self.post)
            .mainSink { _ in
                self.view.layoutNow()
            }.store(in: &self.cancellables)

        self.view.addSubview(self.commentsButton)
        self.commentsButton.showShadow(withOffset: 5)
        self.commentsButton.didSelect { [unowned self] in
            self.animateComments(show: true)
        }

        if post.author == User.current() {
            self.view.addSubview(self.moreButton)
            self.moreButton.didConfirmDeletion = { [unowned self] in
                // Delete post
                post.deleteInBackground { completed, error in
                    self.didFinish?()
                }
            }
        }

        self.view.addSubview(self.consumersView)
        self.consumersView.itemHeight = 40

        self.addKeyboardObservers()

        KeyboardManger.shared.$isKeyboardShowing.mainSink { isShowing in
            if isShowing, !self.isShowingComments {
                self.animateComments(show: true)
            }
        }.store(in: &self.cancellables)

        self.addChild(viewController: self.commentsVC)
        self.commentsVC.collectionViewManager.loadComments()

        self.commentsVC.collectionViewManager.collectionView.onDoubleTap { [unowned self] (doubleTap) in
            if self.commentInputAccessoryView.textView.isFirstResponder {
                self.commentInputAccessoryView.textView.resignFirstResponder()
            }
        }

        self.commentsVC.didTapExit = { [unowned self] in
            if self.commentInputAccessoryView.textView.isFirstResponder {
                self.commentInputAccessoryView.textView.resignFirstResponder()
            }
            self.animateComments(show: false)
        }

        self.commentsVC.collectionViewManager.$comments.mainSink { comments in
            self.commentsButton.set(text: String(comments.count))
        }.store(in: &self.cancellables)
    }

    override func getBottomContent() -> UIView? {
        return nil
    }

    func animateComments(show: Bool) {
        self.isShowingComments = show

        if show {
            self.shouldHideTopView?()
        } else {
            self.didResume?()
        }

        UIView.animate(withDuration: Theme.animationDuration) {
            self.imageView.alpha  = show ? 0.3 : 1.0
            self.commentsButton.alpha = show ? 0.0 : 1.0
            self.moreButton.alpha = show ? 0.0 : 1.0
            self.captionView.alpha = show ? 0.0 : 1.0
            self.view.layoutNow()
        } completion: { completed in
            if show {
                self.commentsVC.collectionViewManager.collectionView.scrollToEnd()
            }
        }
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
        self.commentsVC.view.centerOnX()

        if self.isShowingComments {
            self.commentsVC.view.match(.top, to: .top, of: self.view)
        } else {
            self.commentsVC.view.match(.top, to: .bottom, of: self.view)
        }

        self.moreButton.squaredSize = 80
        self.moreButton.pin(.right, padding: 0)
        self.moreButton.pinToSafeArea(.bottom, padding: SwipeableInputAccessoryView.preferredHeight + Theme.contentOffset)

        self.commentsButton.squaredSize = 60
        self.commentsButton.pin(.right, padding: 10)

        if self.post.author == User.current() {
            self.commentsButton.match(.bottom, to: .top, of: self.moreButton, offset: -10)
        } else {
            self.commentsButton.pinToSafeArea(.bottom, padding: SwipeableInputAccessoryView.preferredHeight + Theme.contentOffset)
        }

        let height = self.captionView.getHeight(for: self.view.width - self.moreButton.width - Theme.contentOffset)
        self.captionView.height = height
        self.captionView.match(.bottom, to: .bottom, of: self.moreButton)
        self.captionView.pin(.left, padding: Theme.contentOffset)

        self.consumersView.setSize()
        self.consumersView.match(.bottom, to: .top, of: self.captionView)
        self.consumersView.pin(.left, padding: Theme.contentOffset)

        self.gradientView.expandToSuperviewWidth()
        self.gradientView.height = self.view.height - self.consumersView.top
        self.gradientView.pin(.bottom)
    }
}

extension PostMediaViewController: SwipeableInputAccessoryViewDelegate {

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, didConfirm sendable: Sendable) {
        guard let post = self.post as? Post else { return }
        self.commentsVC.createComment(with: sendable, post: post)
    }
}
