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

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.captureVC)

        self.view.addSubview(self.vibrancyView)

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

        self.vibrancyView.button.didSelect { [unowned self] in
            switch RitualManager.shared.state {
            case .noRitual:
                self.didTapAddRitual?()
            case .feedAvailable:
                self.showFeed()
            default:
                break 
            }
        }

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

        self.captureVC.view.expandToSuperviewSize()
        self.vibrancyView.expandToSuperviewSize()
        self.feedVC.view.expandToSuperviewSize()
    }

    func animateTabView(shouldShow: Bool) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.vibrancyView.tabView.alpha = shouldShow ? 1.0 : 0.0
        }
    }

    func showFeed() {

        if self.feedVC.parent.isNil {
            self.addChild(viewController: self.feedVC)
            self.view.layoutNow()
        }

        self.willShowFeed?()
        self.vibrancyView.hideAll()
        self.feedVC.showFeed()
    }

    func hideFeed() {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.feedVC.view.alpha = 0
        } completion: { completed in
            self.feedVC.removeFromParent()
            self.vibrancyView.reset()
        }
    }

    private func didTapPost() {
        // do something 
    }
}
