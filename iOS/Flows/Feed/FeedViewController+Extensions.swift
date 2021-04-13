//
//  FeedViewController+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 8/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension FeedViewController: PostsCollectionMangerDelegate {

    func postsManagerDidSetItems(_ manager: PostsCollectionManager) {
        UIView.animate(withDuration: 0.2) {
            self.avatarView.alpha = 1 
            self.postContainerView.alpha = 1 
        }
        self.indicatorView.configure(with: manager.postVCs.count)
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

    func posts(_ manager: PostsCollectionManager, didPause index: Int, shouldHideTop: Bool) {
        self.indicatorView.pauseProgress(at: index)

        if shouldHideTop {
            UIView.animate(withDuration: 0.2) {
                self.avatarView.alpha = 0
                self.indicatorView.alpha = 0
            }
        }
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
