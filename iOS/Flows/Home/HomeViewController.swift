//
//  CenterViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts
import Parse
import Combine

class HomeViewController: ViewController, TransitionableViewController {

    var receivingPresentationType: TransitionType {
        return .home
    }

    var transitionColor: Color {
        return .background1
    }

    lazy var feedVC = FeedViewController()
    lazy var captureVC = ImageCaptureViewController()
    let vibrancyView = HomeVibrancyView()

    var didTapProfile: CompletionOptional = nil
    var didTapChannels: CompletionOptional = nil
    var didTapAddRitual: CompletionOptional = nil

    var willShowFeed: CompletionOptional = nil

    private var topOffset: CGFloat?

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)

        self.addChild(viewController: self.feedVC)
        self.addChild(viewController: self.captureVC)

        self.view.addSubview(self.vibrancyView)

        self.self.captureVC.view.layer.cornerRadius = 20
        self.captureVC.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.captureVC.view.layer.masksToBounds = true

        self.vibrancyView.layer.cornerRadius = 20
        self.vibrancyView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.vibrancyView.layer.masksToBounds = true

        self.vibrancyView.onPan { [unowned self] pan in
            self.handle(pan: pan)
        }

        self.vibrancyView.tabView.profileItem.didSelect = { [unowned self] in
            self.didTapProfile?()
        }

        self.vibrancyView.tabView.postButtonView.button.didSelect { [unowned self] in
            self.didTapPost()
        }

        self.vibrancyView.tabView.channelsItem.didSelect = { [unowned self] in
            self.didTapChannels?()
        }

        self.feedVC.didExit = { [unowned self] in
            self.hideFeed()
        }

        //        self.vibrancyView.button.didSelect { [unowned self] in
        //            switch RitualManager.shared.state {
        //            case .noRitual:
        //                self.didTapAddRitual?()
        //            case .feedAvailable:
        //                self.showFeed()
        //            default:
        //                break
        //            }
        //        }

        self.vibrancyView.tabView.postButtonView.button.publisher(for: \.isHighlighted)
            .removeDuplicates()
            .mainSink { isHighlighted in
                UIView.animate(withDuration: Theme.animationDuration) {
                    //self.vibrancyView.show(blur: !isHighlighted)
                    // self.feedVC.view.alpha = isHighlighted ? 0.0 : 1.0
                }

            }.store(in: &self.cancellables)

        self.captureVC.begin()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.feedVC.view.expandToSuperviewSize()
        let topOffset = FeedCollectionViewController.height + self.view.safeAreaRect.top

        var size = self.view.size
        size.height -= topOffset

        self.captureVC.view.size = size
        self.captureVC.view.centerOnX()
        if self.topOffset.isNil {
            self.captureVC.view.pin(.top, padding: topOffset)
        }

        self.vibrancyView.frame = self.captureVC.view.frame
    }

    func animate(show: Bool) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.vibrancyView.tabView.alpha = show ? 1.0 : 0.0
            self.feedVC.feedCollectionVC.view.alpha = show ? 1.0 : 0.0
        }
    }

    func showFeed() {

        //        if self.feedVC.parent.isNil {
        //            self.view.layoutNow()
        //        }
        //
        //        self.willShowFeed?()
        //        self.feedVC.feedCollectionVC.statusView?.hideAll()
        //        self.feedVC.showFeed()
    }

    func hideFeed() {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.feedVC.view.alpha = 0
        } completion: { completed in
            self.feedVC.removeFromParent()
            self.feedVC.feedCollectionVC.statusView?.reset()
        }
    }

    private func didTapPost() {
        // do something 
    }

    private func handle(pan: UIPanGestureRecognizer) {
        guard let view = pan.view else {return}

        let translation = pan.translation(in: view.superview)

        let minTop = FeedCollectionViewController.height + self.view.safeAreaRect.top

        switch pan.state {
        case .possible:
            break
        case .began:
            self.topOffset = minTop
        case .changed:
            let newTop = minTop + translation.y
            self.topOffset = clamp(newTop, minTop, self.view.height)
            self.captureVC.view.top = self.topOffset!
        case .ended, .cancelled, .failed:
            let diff = (self.view.height - minTop) - self.topOffset!
            let progress = diff / (self.view.height - minTop)
            self.topOffset = progress < 0.65 ? self.view.height : minTop
            UIView.animate(withDuration: Theme.animationDuration) {
                self.captureVC.view.top = self.topOffset!
                self.view.layoutNow()
            } completion: { completed in
                self.animateFeed(show: progress < 0.65)
            }
        @unknown default:
            break
        }

        self.view.layoutNow()
    }

    private func animateFeed(show: Bool) {
        if show {
            self.feedVC.feedCollectionVC.collectionViewManager.loadFeeds()
        } else {
            self.feedVC.feedCollectionVC.collectionViewManager.reset()
        }
    }
}
