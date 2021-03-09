//
//  FeedCollectionViewManager.swift
//  Benji
//
//  Created by Benji Dodgson on 7/28/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol FeedManagerDelegate: AnyObject {
    func feedManagerDidSetItems(_ manager: FeedManager)
    func feed(_ manager: FeedManager, didSelect post: Postable)
    func feedManagerDidFinish(_ manager: FeedManager)
    func feed(_ manager: FeedManager, didPause index: Int)
    func feed(_ manager: FeedManager, didFinish index: Int)
    func feed(_ manager: FeedManager,
              didShowViewAt index: Int,
              with duration: TimeInterval)
}

class FeedManager: NSObject {

    private(set) var currentIndex: Int = 0
    private var current: PostViewController?
    private(set) var posts: [PostViewController] = [] {
        didSet {
            self.delegate.feedManagerDidSetItems(self)
        }
    }
    
    private unowned let delegate: FeedManagerDelegate
    private unowned let parentVC: ViewController
    private unowned let container: View

    init(with parentVC: ViewController,
         container: View,
         delegate: FeedManagerDelegate) {

        self.parentVC = parentVC
        self.delegate = delegate
        self.container = container

        super.init()
    }

    func set(items: [Postable]) {

        var postVCs: [PostViewController] = []

        for (index, post) in items.enumerated() {

            let postVC: PostViewController

            switch post.type {
            case .timeSaved:
                postVC = PostIntroViewController(with: post)
            case .newChannel:
                postVC = PostNewChannelViewController(with: post)
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
            }

            postVCs.append(postVC)

            postVC.didFinish = { [unowned self] in
                self.delegate.feed(self, didFinish: index)
            }

            postVC.didSelectPost = { [unowned self] in
                self.delegate.feed(self, didSelect: post)
            }

            postVC.didPause = { [unowned self] in
                self.delegate.feed(self, didPause: index)
            }
        }

        self.posts = postVCs
        self.showFirst()
    }

    func showFirst() {
        if let first = self.posts.first {
            self.show(postVC: first, at: 0)
        }
    }

    func advanceToNextView(from index: Int) {
        if let next = self.posts[safe: index + 1]  {
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
                self.delegate.feed(self, didShowViewAt: index, with: TimeInterval(postVC.post.duration))
            }
        }
    }

    private func finishFeed() {
        UIView.animate(withDuration: 0.2) {
            self.current?.view.alpha = 0
        } completion: { (completed) in
            self.delegate.feedManagerDidFinish(self)
        }
    }
}
