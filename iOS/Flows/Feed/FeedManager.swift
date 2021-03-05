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
    func feed(_ manager: FeedManager, didSelect type: PostType)
    func feedManagerDidFinish(_ manager: FeedManager)
    func feed(_ manager: FeedManager, didPause index: Int)
    func feed(_ manager: FeedManager, didFinish index: Int)
    func feed(_ manager: FeedManager,
              didShowViewAt index: Int,
              with duration: TimeInterval)
}

class FeedManager: NSObject {

    private var current: PostViewController?
    private(set) var posts: [PostViewController] = [] {
        didSet {
            self.delegate.feedManagerDidSetItems(self)
        }
    }
    
    private unowned let delegate: FeedManagerDelegate
    private unowned let parentVC: ViewController

    init(with parentVC: ViewController, delegate: FeedManagerDelegate) {
        self.parentVC = parentVC
        self.delegate = delegate
        super.init()
    }

    func set(items: [PostType]) {

        var postVCs: [PostViewController] = []

        for (index, type) in items.enumerated() {

            let postVC: PostViewController

            switch type {
            case .timeSaved(_):
                postVC = PostIntroViewController(with: type)
            case .ritual:
                postVC = PostRitualViewController(with: type)
            case .newChannel(_):
                postVC = PostNewChannelViewController(with: type)
            case .unreadMessages(_, _):
                postVC = PostUnreadViewController(with: type)
            case .channelInvite(_):
                postVC = PostChannelInviteViewController(with: type)
            case .connectionRequest(_):
                postVC = PostConnectionViewController(with: type)
            case .inviteAsk(_):
                postVC = PostReservationViewController(with: type)
            case .notificationPermissions:
                postVC = PostNotificationPermissionsViewController(with: type)
            case .meditation:
                postVC = PostMeditationViewController(with: type)
            }

            postVCs.append(postVC)

            postVC.didFinish = { [unowned self] in
                self.delegate.feed(self, didFinish: index)
            }

            postVC.didSelectPost = { [unowned self] in
                self.delegate.feed(self, didSelect: type)
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
            self.show(post: first, at: 0)
        }
    }

    func advanceToNextView(from index: Int) {
        if let next = self.posts[safe: index + 1]  {
            self.show(post: next, at: index + 1)
        } else {
            self.finishFeed()
        }
    }

    private func show(post: PostViewController, at index: Int) {
        let duration: TimeInterval = self.current.isNil ? 0 : 0.2
        UIView.animate(withDuration: duration) {
            self.current?.view.alpha = 0
        } completion: { (completed) in
            self.current?.removeFromParentSuperview()
            self.current = post
            post.view.alpha = 0
            self.parentVC.addChild(viewController: post)
            post.view.expandToSuperviewSize()
            post.view.layoutNow()
            UIView.animate(withDuration: 0.2) {
                post.view.alpha = 1
            } completion: { (completed) in
                self.delegate.feed(self, didShowViewAt: index, with: post.type.duration)
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
