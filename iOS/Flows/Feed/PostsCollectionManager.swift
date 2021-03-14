//
//  FeedCollectionViewManager.swift
//  Benji
//
//  Created by Benji Dodgson on 7/28/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

protocol PostsCollectionManger: AnyObject {
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
    private(set) var postVCs: [PostViewController] = [] {
        didSet {
            self.delegate.postsManagerDidSetItems(self)
        }
    }
    
    private unowned let delegate: PostsCollectionManger
    private unowned let parentVC: ViewController
    private unowned let container: View

    private var cancellables = Set<AnyCancellable>()

    init(with parentVC: ViewController,
         container: View,
         delegate: PostsCollectionManger) {

        self.parentVC = parentVC
        self.delegate = delegate
        self.container = container

        super.init()

        self.subscribeToUpdates()
    }

    private func subscribeToUpdates() {
        PostsSupplier.shared.$posts.mainSink { posts in
            self.set(items: posts)
        }.store(in: &self.cancellables)
    }

    private func set(items: [Postable]) {

        var postVCs: [PostViewController] = []

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

            postVCs.append(postVC)

            postVC.didFinish = { [unowned self] in
                self.delegate.posts(self, didFinish: index)
            }

            postVC.didSelectPost = { [unowned self] in
                self.delegate.posts(self, didSelect: post, at: index)
            }

            postVC.didPause = { [unowned self] in
                self.delegate.posts(self, didPause: index)
            }
        }

        self.postVCs = postVCs
        self.showFirst()
    }

    func showFirst() {
        if let first = self.postVCs.first {
            self.show(postVC: first, at: 0)
        }
    }

    func advanceToNextView(from index: Int) {
        if let next = self.postVCs[safe: index + 1]  {
            self.show(postVC: next, at: index + 1)
        } else {
            self.finishFeed()
        }
    }
    
    private func show(postVC: PostViewController, at index: Int) {
        self.currentIndex = index 
        let duration: TimeInterval = self.current.isNil ? 0 : 0.2
        UIView.animate(withDuration: duration) {
            self.current?.view.alpha = 0
        } completion: { (completed) in
            self.current?.removeFromParentSuperview()
            self.current = postVC
            postVC.view.alpha = 0
            self.parentVC.addChild(viewController: postVC, toView: self.container)
            postVC.view.expandToSuperviewSize()
            postVC.view.layoutNow()
            UIView.animate(withDuration: 0.2) {
                postVC.view.alpha = 1
            } completion: { (completed) in
                self.delegate.posts(self, didShowViewAt: index, with: TimeInterval(postVC.post.duration))
            }
        }
    }

    private func finishFeed() {
        UIView.animate(withDuration: 0.2) {
            self.current?.view.alpha = 0
        } completion: { (completed) in
            self.delegate.postsManagerDidEndDisplaying(self)
        }
    }

    func reset() {
        self.current = nil
        self.currentIndex = 0
        self.postVCs = []
    }
}
