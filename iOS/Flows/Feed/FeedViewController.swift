//
//  HomeStackViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Lottie

protocol FeedViewControllerDelegate: AnyObject {
    func feedView(_ controller: FeedViewController, didSelect post: Postable)
}

class FeedViewController: ViewController {

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    let manager = PostsCollectionManager()

    weak var delegate: FeedViewControllerDelegate?

    private let reloadButton = Button()
    let postContainerView = View()
    let indicatorView = FeedIndicatorView()
    let animationView = AnimationView(name: "loading")
    let avatarView = AvatarView()

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.blurView)

        // Initializes the manager. 
        self.manager.delegate = self
        self.manager.parentVC = self
        self.manager.container = self.postContainerView

        self.view.addSubview(self.reloadButton)

        self.reloadButton.alpha = 0

        self.reloadButton.set(style: .normal(color: .white, text: "Reload"))
        self.reloadButton.didSelect { [unowned self] in
            self.reloadFeed()
        }

        self.view.addSubview(self.postContainerView)
        self.postContainerView.layer.cornerRadius = 20
        self.postContainerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        self.postContainerView.layer.masksToBounds = true
        self.postContainerView.alpha = 0
        
        self.view.addSubview(self.animationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .loop
        self.animationView.play()

        self.view.addSubview(self.indicatorView)
        self.indicatorView.alpha = 1
        self.indicatorView.delegate = self 

        self.view.addSubview(self.avatarView)
        self.avatarView.alpha = 0
        
        FeedManager.shared.$selectedFeed.mainSink { feed in
            if let f = feed {
                f.owner?.retrieveDataIfNeeded()
                    .mainSink(receiveValue: { user in
                        self.avatarView.set(avatar: user)
                    }).store(in: &self.cancellables)
            }
        }.store(in: &self.cancellables)

        self.manager.loadPosts()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        self.reloadButton.size = CGSize(width: 140, height: 40)
        self.reloadButton.centerOnXAndY()

        self.indicatorView.size = CGSize(width: self.view.width - 20, height: 2)
        self.indicatorView.pinToSafeArea(.top, padding: Theme.contentOffset)
        self.indicatorView.centerOnX()

        self.postContainerView.expandToSuperviewSize()
        self.postContainerView.centerOnX()
        self.postContainerView.pinToSafeArea(.top, padding: 0)

        self.animationView.size = CGSize(width: 18, height: 18)
        self.animationView.centerOnXAndY()

        self.avatarView.setSize(for: 60)
        self.avatarView.pin(.left, padding: Theme.contentOffset)
        self.avatarView.match(.top, to: .bottom, of: self.indicatorView, offset: Theme.contentOffset)
    }

    func showReload() {
        self.view.bringSubviewToFront(self.reloadButton)
        self.view.layoutNow()
        UIView.animate(withDuration: Theme.animationDuration, delay: Theme.animationDuration, options: .curveEaseInOut, animations: {
            self.reloadButton.alpha = 1
            self.indicatorView.alpha = 0
            self.postContainerView.alpha = 0
            self.avatarView.alpha = 0
        }, completion: { _ in })
    }

    private func reloadFeed() {
        self.view.sendSubviewToBack(self.reloadButton)
        UIView.animate(withDuration: Theme.animationDuration, delay: 0, options: .curveEaseInOut, animations: {
            self.reloadButton.alpha = 0
            self.indicatorView.alpha = 1
            self.postContainerView.alpha = 1
            self.avatarView.alpha = 1
            self.indicatorView.resetAllIndicators()
        }, completion: { completed in
            self.manager.showFirst()
        })
    }
}
