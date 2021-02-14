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
    func feed(_ manager: FeedManager, didSkip index: Int)
    func feed(_ manager: FeedManager,
              didShowViewAt index: Int,
              with duration: TimeInterval)
}

class FeedManager: NSObject {

    private var current: FeedView?
    private(set) var posts: [FeedView] = [] {
        didSet {
            self.delegate.feedManagerDidSetItems(self)
        }
    }
    private let containerView: UIView
    private unowned let delegate: FeedManagerDelegate

    init(with container: UIView, delegate: FeedManagerDelegate) {
        self.containerView = container
        self.delegate = delegate
        super.init()
    }

    func set(items: [PostType]) {

        var views: [FeedView] = []

        for (index, type) in items.enumerated() {
            let view = FeedView(with: type)
            view.didSelect = { [unowned self] in
                self.delegate.feed(self, didSelect: type)
            }
            view.didSkip = { [unowned self] in
                self.delegate.feed(self, didSkip: index)
            }

            views.append(view)
        }

        self.posts = views
        self.showFirst()
    }

    func showFirst() {
        if let first = self.posts.first {
            self.show(view: first, at: 0)
        }
    }

    func advanceToNextView(from index: Int) {
        if let nextView = self.posts[safe: index + 1]  {
            self.show(view: nextView, at: index + 1)
        } else {
            self.finishFeed()
        }
    }

    private func show(view: FeedView, at index: Int) {
        let duration: TimeInterval = self.current.isNil ? 0 : 0.2
        UIView.animate(withDuration: duration) {
            self.current?.alpha = 0
        } completion: { (completed) in
            self.current?.removeFromSuperview()
            self.current = view
            view.alpha = 0
            self.containerView.addSubview(view)
            view.expandToSuperviewSize()
            view.layoutNow()
            UIView.animate(withDuration: 0.2) {
                view.alpha = 1
            } completion: { (completed) in
                self.delegate.feed(self, didShowViewAt: index, with: view.feedType.duration)
            }
        }
    }

    private func finishFeed() {
        UIView.animate(withDuration: 0.2) {
            self.current?.alpha = 0
        } completion: { (completed) in
            self.delegate.feedManagerDidFinish(self)
        }
    }
}
