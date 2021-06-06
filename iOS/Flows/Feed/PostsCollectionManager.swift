//
//  FeedCollectionViewManager.swift
//  Benji
//
//  Created by Benji Dodgson on 7/28/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

protocol PostsCollectionMangerDelegate: AnyObject {
    func postsManagerDidNotFindPosts(_ manager: PostsCollectionManager)
    func postsManagerDidSetItems(_ manager: PostsCollectionManager, for user: User)
    func posts(_ manager: PostsCollectionManager, didSelect post: Postable, at index: Int)
    func postsManagerDidEndDisplaying(_ manager: PostsCollectionManager)
    func posts(_ manager: PostsCollectionManager, didPause index: Int)
    func posts(_ manager: PostsCollectionManager, shouldHideTop: Bool)
    func posts(_ manager: PostsCollectionManager, didResume index: Int)
    func posts(_ manager: PostsCollectionManager, didFinish index: Int)
    func posts(_ manager: PostsCollectionManager, didGoBackTo index: Int, with duration: TimeInterval)
    func posts(_ manager: PostsCollectionManager,
               didShowViewAt index: Int,
               with duration: TimeInterval)
}

class PostsCollectionManager: NSObject {

    private(set) var currentIndex: Int = 0
    private var current: PostViewController?
    private(set) var postVCs: [PostViewController] = []
    
    weak var delegate: PostsCollectionMangerDelegate?
    weak var parentVC: ViewController?
    weak var container: View?

    let threshold: CGFloat = 10 // Distance, in points, a pan must move horizontally before a animation
    let distance: CGFloat = 250 // Distance that a pan must move to fully animate
    var interactionInProgress = false // If we're currently progressing
    var panStartPoint = CGPoint() // Where the pan gesture began
    var startPoint = CGPoint() // Where the pan gesture was when animation was started

    private var isResetting: Bool = false
    private var cancellables = Set<AnyCancellable>()
    private var finishAnimator: UIViewPropertyAnimator?

    var transitionAnimator: UIViewPropertyAnimator?

    private(set) var feedOwner: User?

    func loadPosts(for user: User) {
        self.feedOwner = user 
        self.isResetting = false
        self.postVCs = []
        PostsSupplier.shared.getPosts(for: user)
            .mainSink { posts in
                self.postVCs = []
                if posts.count > 0 {
                    self.set(items: posts)
                } else {
                    self.delegate?.postsManagerDidNotFindPosts(self)
                }
            }.store(in: &self.cancellables)
    }

    private func set(items: [Postable]) {

        for (index, post) in items.enumerated() {

            let postVC: PostViewController

            switch post.type {
            case .timeSaved:
                postVC = PostIntroViewController(with: post)
            case .unreadMessages:
                postVC = PostUnreadViewController(with: post)
            case .channelInvite:
                postVC = PostChannelInviteViewController(with: post)
            case .connectionRequest:
                postVC = PostConnectionViewController(with: post)
            case .inviteAsk:
                postVC = PostReservationViewController(with: post)
            case .notificationPermissions:
                postVC = PostNotificationPermissionsViewController(with: post)
            case .meditation:
                postVC = PostMeditationViewController(with: post)
            case .media:
                postVC = PostMediaViewController(with: post)
            }

            self.postVCs.append(postVC)

            postVC.didFinish = { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.posts(self, didFinish: index)
            }

            postVC.didSelectPost = { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.posts(self, didSelect: post, at: index)
            }

            postVC.didPause = { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.posts(self, didPause: index)
            }

            postVC.shouldHideTopView = { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.posts(self, shouldHideTop: true)
            }

            postVC.didResume = { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.posts(self, didResume: index)
            }

            postVC.handlePan = { [weak self] pan in
                guard let `self` = self else { return }
                self.handle(pan: pan, for: postVC)
            }

            postVC.didGoBack = { [weak self] in
                guard let `self` = self else { return }
                let previous = clamp(index - 1, min: 0)
                if let previousVC = self.postVCs[safe: previous] {
                    self.delegate?.posts(self, didGoBackTo: previous, with: TimeInterval(previousVC.post.duration))
                    self.transition(to: previousVC, at: previous, option: .transitionFlipFromLeft)
                }
            }
        }

        // Show first
        if let first = self.postVCs.first {
            self.transition(to: first, at: 0)
        }

        if let user = self.feedOwner {
            self.delegate?.postsManagerDidSetItems(self, for: user)
        }
    }

    func transition(to: PostViewController,
                    at index: Int,
                    option: UIView.AnimationOptions = .transitionFlipFromRight) {

        guard let parent = self.parentVC, let container = self.container else { return }

        self.transitionAnimator = nil 

        if self.transitionAnimator.isNil {
            self.transitionAnimator = self.createAnimator()
        }

        parent.addChild(viewController: to, toView: self.container)
        to.view.isHidden = true
        to.view.expandToSuperviewSize()
        to.view.layoutNow()
        to.configurePost()

        self.transitionAnimator?.addAnimations {
            if let from = self.current {
                UIView.transition(with: container,
                                  duration: 0.0,
                                  options: [option],
                                  animations: {
                                    to.view.isHidden = false
                                    from.view.isHidden = true
                    })
            } else {
                to.view.isHidden = false
            }
        }

        self.transitionAnimator?.addCompletion({ [weak self] position in
            guard let `self` = self else { return }

            self.currentIndex = index
            self.current?.removeFromParentSuperview()
            self.current = to

            self.delegate?.posts(self, didShowViewAt: index, with: TimeInterval(to.post.duration))

            self.transitionAnimator = nil
        })

        self.transitionAnimator?.startAnimation()
    }

    func advanceToNextView(from index: Int) {
        self.current?.resignFirstResponder()

        if let next = self.postVCs[safe: index + 1]  {
            self.consumeIfNeccessary()
            self.transition(to: next, at: index + 1)
        } else if !self.isResetting {
            self.finishFeed()
        }
    }

    private func consumeIfNeccessary() {
        guard let current = self.current,
              current.post.type == .media,
              current.post.author != User.current(),
              let post = current.post as? Post else { return }

        post.addCurrentUserAsConsumer()
    }

    private func finishFeed() {

        if let animator = self.finishAnimator {
            self.stop(animator: animator)
        }

        self.finishAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .linear, animations: { [weak self] in
            guard let `self` = self else { return }
            self.current?.view.alpha = 0
        })

        self.finishAnimator?.addCompletion({ [weak self] position in
            guard let `self` = self, position == .end else { return }
            self.current = nil
            self.checkForNextFeed()
        })

        self.finishAnimator?.startAnimation()
    }

    func checkForNextFeed() {
        if let user = self.feedOwner,
           let next = FeedManager.shared.getNextAvailableFeed(after: user),
           let nextOwner = next.owner {
            self.loadPosts(for: nextOwner)
        } else {
            self.delegate?.postsManagerDidEndDisplaying(self)
        }
    }

    func reset() {
        self.isResetting = true
        self.current = nil
        self.currentIndex = 0
        self.postVCs.forEach { vc in
            vc.removeFromParent()
        }

        [self.transitionAnimator, self.finishAnimator].forEach { animator in
            if let a = animator {
                self.stop(animator: a)
            }
        }
    }

    private func stop(animator: UIViewPropertyAnimator) {
        if animator.state == .active {
            animator.stopAnimation(false)
            animator.finishAnimation(at: .start)
        } else if animator.state == .stopped {
            animator.finishAnimation(at: .start)
        } else if animator.isRunning {
            animator.stopAnimation(false)
            animator.finishAnimation(at: .start)
        }
    }
}
