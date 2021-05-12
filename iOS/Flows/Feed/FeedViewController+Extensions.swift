//
//  FeedViewController+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 8/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension FeedViewController: PostsCollectionMangerDelegate {

    func posts(_ manager: PostsCollectionManager,
               didGoBackTo index: Int,
               with duration: TimeInterval) {
        self.indicatorView.goBack(to: index, with: duration)
    }

    func posts(_ manager: PostsCollectionManager, shouldHideTop: Bool) {
        if shouldHideTop {
            UIView.animate(withDuration: 0.2) {
                self.avatarView.alpha = 0
                self.indicatorView.alpha = 0
            }
        }
    }

    func postsManagerDidNotFindPosts(_ manager: PostsCollectionManager) {
        self.state = .noPosts
    }

    func postsManagerDidSetItems(_ manager: PostsCollectionManager, for user: User) {
        self.state = .showingFeed
        self.indicatorView.configure(with: manager.postVCs.count)
        user.retrieveDataIfNeeded()
            .mainSink(receiveValue: { user in
                self.avatarView.set(avatar: user)
            }).store(in: &self.cancellables)
    }

    func posts(_ manager: PostsCollectionManager,
               didSelect post: Postable,
               at index: Int) {
        self.indicatorView.pauseProgress(at: index)
        self.delegate?.feedView(self, didSelect: post)
    }

    func postsManagerDidEndDisplaying(_ manager: PostsCollectionManager) {
        self.state = .finished
    }

    func posts(_ manager: PostsCollectionManager, didFinish index: Int) {
        self.indicatorView.finishProgress(at: index)
    }

    func posts(_ manager: PostsCollectionManager, didPause index: Int) {
        self.indicatorView.pauseProgress(at: index)
    }

    func posts(_ manager: PostsCollectionManager, didResume index: Int) {
        self.indicatorView.resumeProgress(at: index)

        if self.avatarView.alpha < 1.0 {
            UIView.animate(withDuration: 0.2) {
                self.avatarView.alpha = 1
                self.indicatorView.alpha = 1
            }
        }
    }

    func posts(_ manager: PostsCollectionManager,
              didShowViewAt index: Int,
              with duration: TimeInterval) {
        if self.animationView.isAnimationPlaying {
            self.animationView.stop()
        }
        self.indicatorView.update(to: index, with: duration)
    }
}

extension FeedViewController: FeedIndicatorViewDelegate {
    func feedIndicator(_ view: FeedIndicatorView, didFinishProgressFor index: Int) {
        self.manager.advanceToNextView(from: index)
    }
}
