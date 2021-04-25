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

    private let doneButton = Button()
    private let emojiLabel = Label(font: .display)
    private let doneLabel = Label(font: .mediumBold)

    var didTapDone: CompletionOptional = nil

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

        self.view.addSubview(self.doneButton)
        self.view.addSubview(self.doneLabel)
        self.view.addSubview(self.emojiLabel)

        self.emojiLabel.textAlignment = .center
        self.emojiLabel.setText("😊")
        self.emojiLabel.alpha = 0

        self.doneLabel.setText("Take a deep breath.\nYou're all caught up.")
        self.doneLabel.textAlignment = .center
        self.doneButton.alpha = 0
        self.doneLabel.alpha = 0

        self.doneButton.set(style: .normal(color: .purple, text: "Done"))
        self.doneButton.didSelect { [unowned self] in
            self.manager.reset()
            self.didTapDone?()
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
    }

    func loadPosts(for user: User) {
        user.retrieveDataIfNeeded()
            .mainSink(receiveValue: { user in
                self.avatarView.set(avatar: user)
            }).store(in: &self.cancellables)
        self.manager.loadPosts(for: user)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        self.doneLabel.setSize(withWidth: self.view.width - Theme.contentOffset.doubled)
        self.doneLabel.centerOnXAndY()

        self.emojiLabel.setSize(withWidth: self.view.width)
        self.emojiLabel.centerOnX()
        self.emojiLabel.match(.bottom, to: .top, of: self.doneLabel, offset: -Theme.contentOffset)

        self.doneButton.setSize(with: self.view.width)
        self.doneButton.centerOnX()
        self.doneButton.pinToSafeArea(.bottom, padding: 0)

        self.indicatorView.size = CGSize(width: self.view.width - Theme.contentOffset.doubled, height: 2)
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

    func showDone() {
        self.view.bringSubviewToFront(self.doneButton)
        self.view.layoutNow()
        UIView.animate(withDuration: Theme.animationDuration, delay: Theme.animationDuration, options: .curveEaseInOut, animations: {
            self.doneButton.alpha = 1
            self.doneLabel.alpha = 1
            self.emojiLabel.alpha = 1
            
            self.postContainerView.alpha = 0
            self.indicatorView.alpha = 0
            self.avatarView.alpha = 0
        }, completion: { _ in })
    }
}
