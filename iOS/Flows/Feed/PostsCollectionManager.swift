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
    func postsManagerDidSetItems(_ manager: PostsCollectionManager)
    func posts(_ manager: PostsCollectionManager, didSelect post: Postable, at index: Int)
    func postsManagerDidEndDisplaying(_ manager: PostsCollectionManager)
    func posts(_ manager: PostsCollectionManager, didPause index: Int, shouldHideTop: Bool)
    func posts(_ manager: PostsCollectionManager, didResume index: Int)
    func posts(_ manager: PostsCollectionManager, didFinish index: Int)
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

    private var isResetting: Bool = false
    private var cancellables = Set<AnyCancellable>()

    private var hideAnimator: UIViewPropertyAnimator?
    private var showAnimator: UIViewPropertyAnimator?
    private var finishAnimator: UIViewPropertyAnimator?

    func loadPosts() {
        self.isResetting = false
        self.postVCs = []
        PostsSupplier.shared.$posts
            .mainSink { posts in
                self.postVCs = []
                if posts.count > 0 {
                    self.set(items: posts)
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
                self.delegate?.posts(self, didPause: index, shouldHideTop: false)
            }

            postVC.shouldHideTopView = { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.posts(self, didPause: index, shouldHideTop: true)
            }

            postVC.didResume = { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.posts(self, didResume: index)
            }
        }

        // Show first
        if let first = self.postVCs.first {
            self.show(postVC: first, at: 0)
        }

        self.delegate?.postsManagerDidSetItems(self)
    }

    func advanceToNextView(from index: Int) {
        if let next = self.postVCs[safe: index + 1]  {
            self.consumeIfNeccessary()
            self.show(postVC: next, at: index + 1)
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
    
    private func show(postVC: PostViewController, at index: Int) {
        self.currentIndex = index 
        let duration: TimeInterval = self.current.isNil ? 0 : 0.2

        if let animator = self.hideAnimator {
            self.stop(animator: animator)
        }

        self.hideAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear, animations: { [weak self] in
            guard let `self` = self, self.current != postVC else { return }
            self.current?.view.alpha = 0
        })

        self.hideAnimator?.addCompletion({ [weak self] position in
            guard let `self` = self else { return }
            guard position == .end, postVC != self.current else { return }
            self.current?.removeFromParentSuperview()
            self.current = postVC
            postVC.view.alpha = 0
            self.parentVC?.addChild(viewController: postVC, toView: self.container)
            postVC.view.expandToSuperviewSize()
            postVC.view.layoutNow()

            if let animator = self.showAnimator {
                self.stop(animator: animator)
            }
            self.showAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .linear, animations: { [weak self] in
                guard let `self` = self else { return }
                self.current?.view.alpha = 1
            })

            self.showAnimator?.addCompletion({ [weak self] position in
                guard let `self` = self, position == .end, index == self.currentIndex else { return }
                self.delegate?.posts(self, didShowViewAt: index, with: TimeInterval(postVC.post.duration))
            })

            self.showAnimator?.startAnimation()
        })

        self.hideAnimator?.startAnimation()
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
            self.delegate?.postsManagerDidEndDisplaying(self)
        })

        self.finishAnimator?.startAnimation()
    }

    func reset() {
        self.isResetting = true
        self.current = nil
        self.currentIndex = 0
        self.postVCs.forEach { vc in
            vc.removeFromParent()
        }

        [self.hideAnimator, self.showAnimator, self.finishAnimator].forEach { animator in
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
