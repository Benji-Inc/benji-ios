//
//  FeedViewController+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 8/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension FeedViewController {

    func addItems() {
        self.animationView.play()
        PostsSupplier.shared.getItems()
            .mainSink(receiveValue: { (items) in
                self.manager.set(items: items)
                self.animationView.stop()
            }).store(in: &self.cancellables)
    }

    func addFirstItems() {
        PostsSupplier.shared.getFirstItems()
            .mainSink(receiveValue: { (items) in
                self.manager.set(items: items)
                self.showFeed()
            }).store(in: &self.cancellables)
    }
}

extension FeedViewController: PostsCollectionManger {

    func postsManagerDidSetItems(_ manager: PostsCollectionManager) {
        self.indicatorView.configure(with: manager.posts.count)
    }

    func posts(_ manager: PostsCollectionManager,
               didSelect post: Postable,
               at index: Int) {
        
        self.indicatorView.pauseProgress(at: index)
        self.delegate?.feedView(self, didSelect: post)
    }

    func postsManagerDidEndDisplaying(_ manager: PostsCollectionManager) {
        self.showReload()
    }

    func posts(_ manager: PostsCollectionManager, didFinish index: Int) {
        self.indicatorView.finishProgress(at: index)
    }

    func posts(_ manager: PostsCollectionManager, didPause index: Int) {
        self.indicatorView.pauseProgress(at: index)
    }

    func posts(_ manager: PostsCollectionManager,
              didShowViewAt index: Int,
              with duration: TimeInterval) {
        self.indicatorView.update(to: index, with: duration)
    }
}

extension FeedViewController: FeedIndicatorViewDelegate {
    func feedIndicator(_ view: FeedIndicatorView, didFinishProgressFor index: Int) {
        self.manager.advanceToNextView(from: index)
    }
}
