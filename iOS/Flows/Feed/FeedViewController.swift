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

    lazy var feedCollectionVC = FeedCollectionViewController()

    lazy var manager: PostsCollectionManager = {
        let manager = PostsCollectionManager(with: self, container: self.postContainerView, delegate: self)
        return manager
    }()

    weak var delegate: FeedViewControllerDelegate?

    private let reloadButton = Button()
    private let closeButton = UIButton()
    private let postContainerView = View()
    lazy var indicatorView = FeedIndicatorView(with: self)
    let animationView = AnimationView(name: "loading")
    let gradientView = FeedGradientView()
    var didExit: CompletionOptional = nil

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.feedCollectionVC)

        self.view.addSubview(self.reloadButton)

        self.reloadButton.alpha = 0
        self.view.addSubview(self.indicatorView)
        self.indicatorView.alpha = 0

        self.reloadButton.set(style: .normal(color: .white, text: "Reload"))
        self.reloadButton.didSelect { [unowned self] in
            self.reloadFeed()
        }

        self.view.addSubview(self.gradientView)
        self.gradientView.alpha = 0
        self.view.addSubview(self.closeButton)
        self.closeButton.setImage(UIImage(systemName: "xmark")!, for: .normal)
        self.closeButton.contentMode = .center
        self.closeButton.tintColor = Color.white.color
        self.closeButton.alpha = 0

        self.closeButton.didSelect { [unowned self] in
            self.feedCollectionVC.collectionViewManager.reset()
            self.indicatorView.resetAllIndicators()
            self.manager.reset()
            self.closeButton.alpha = 0
            self.gradientView.alpha = 0 
            self.didExit?()
        }

        self.view.addSubview(self.postContainerView)

        self.postContainerView.addSubview(self.animationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .loop
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.feedCollectionVC.view.expandToSuperviewWidth()
        self.feedCollectionVC.view.height = FeedCollectionViewController.height
        self.feedCollectionVC.view.pinToSafeArea(.top, padding: 0)

        self.gradientView.height = self.feedCollectionVC.view.height
        self.gradientView.match(.top, to: .top, of: self.feedCollectionVC.view)
        self.gradientView.width = self.view.width * 0.36
        self.gradientView.pin(.right)

        self.reloadButton.size = CGSize(width: 140, height: 40)
        self.reloadButton.centerOnXAndY()

        self.indicatorView.size = CGSize(width: self.view.width - 20, height: 2)
        self.indicatorView.pinToSafeArea(.top, padding: 0)
        self.indicatorView.centerOnX()

        self.closeButton.squaredSize = 44
        self.closeButton.centerY = self.feedCollectionVC.view.centerY
        self.closeButton.match(.right, to: .right, of: self.indicatorView)

        self.postContainerView.height = self.view.height - self.closeButton.bottom
        self.postContainerView.expandToSuperviewWidth()
        self.postContainerView.centerOnX()
        self.postContainerView.match(.top, to: .bottom, of: self.feedCollectionVC.view)

        self.animationView.size = CGSize(width: 18, height: 18)
        self.animationView.centerOnXAndY()
    }

    func showReload() {
        self.view.bringSubviewToFront(self.reloadButton)
        self.view.layoutNow()
        UIView.animate(withDuration: Theme.animationDuration, delay: Theme.animationDuration, options: .curveEaseInOut, animations: {
            self.reloadButton.alpha = 1
            self.indicatorView.alpha = 0
        }, completion: { _ in })
    }

    private func reloadFeed() {
        self.view.sendSubviewToBack(self.reloadButton)
        UIView.animate(withDuration: Theme.animationDuration, delay: 0, options: .curveEaseInOut, animations: {
            self.reloadButton.alpha = 0
            self.indicatorView.alpha = 1
            self.indicatorView.resetAllIndicators()
        }, completion: { completed in
            self.manager.showFirst()
        })
    }

    func showFeed() {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.view.alpha = 1 
            self.indicatorView.alpha = 1
            self.closeButton.alpha = 1
            self.reloadButton.alpha = 0
            self.gradientView.alpha = 1
        } completion: { completed in
            self.feedCollectionVC.collectionViewManager.loadFeeds()
        }
    }
}
