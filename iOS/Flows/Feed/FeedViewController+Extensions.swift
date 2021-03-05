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
                self.view.layoutNow()
                self.manager.set(items: items)
                self.animationView.stop()
            }).store(in: &self.cancellables)
    }

    func addFirstItems() {
        PostsSupplier.shared.getFirstItems()
            .mainSink(receiveValue: { (items) in
                self.view.layoutNow()
                self.manager.set(items: items)
                self.showFeed()
            }).store(in: &self.cancellables)
    }
}

extension FeedViewController: FeedManagerDelegate {

    func feedManagerDidSetItems(_ manager: FeedManager) {
        self.indicatorView.configure(with: manager.posts.count)
    }

    func feed(_ manager: FeedManager, didSelect type: PostType) {
        self.delegate?.feedView(self, didSelect: type)
    }

    func feedManagerDidFinish(_ manager: FeedManager) {
        self.showReload()
    }

    func feed(_ manager: FeedManager, didFinish index: Int) {
        self.indicatorView.finishProgress(at: index)
    }

    func feed(_ manager: FeedManager, didPause index: Int) {
        self.indicatorView.pauseProgress(at: index)
    }

    func feed(_ manager: FeedManager,
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
