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
    func posts(_ manager: PostsCollectionManager, didPause index: Int)
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

    func loadPosts() {
        self.isResetting = false
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
                self.delegate?.posts(self, didPause: index)
            }
        }

        self.showFirst()
        self.delegate?.postsManagerDidSetItems(self)
    }

    func showFirst() {
        if let first = self.postVCs.first {
            self.show(postVC: first, at: 0)
        }
    }

    func advanceToNextView(from index: Int) {
        if let next = self.postVCs[safe: index + 1]  {
            self.show(postVC: next, at: index + 1)
        } else if !self.isResetting {
            self.finishFeed()
        }
    }
    
    private func show(postVC: PostViewController, at index: Int) {
        self.currentIndex = index 
        let duration: TimeInterval = self.current.isNil ? 0 : 0.2
        UIView.animate(withDuration: duration) { [weak self] in
            guard let `self` = self, self.current != postVC else { return }
            self.current?.view.alpha = 0
        } completion: { (completed) in
            guard postVC != self.current else { return }
            self.current?.removeFromParentSuperview()
            self.current = postVC
            postVC.view.alpha = 0
            self.parentVC?.addChild(viewController: postVC, toView: self.container)
            postVC.view.expandToSuperviewSize()
            postVC.view.layoutNow()
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let `self` = self else { return }
                self.current?.view.alpha = 1
            } completion: { [weak self] (completed) in
                guard let `self` = self, index == self.currentIndex else { return }
                self.delegate?.posts(self, didShowViewAt: index, with: TimeInterval(postVC.post.duration))
            }
        }
    }

    private func finishFeed() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let `self` = self else { return }
            self.current?.view.alpha = 0
        } completion: { [weak self] (completed) in
            guard let `self` = self else { return }
            self.current = nil
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
    }
}
