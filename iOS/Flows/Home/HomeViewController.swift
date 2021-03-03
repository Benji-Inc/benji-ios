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

    let centerContainer = View()
    let tabView = HomeTabView()

    var didTapProfile: CompletionOptional = nil
    var didTapChannels: CompletionOptional = nil

    private let vibrancyView = VibrancyView()

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.vibrancyView)
        self.view.addSubview(self.centerContainer)
        self.view.addSubview(self.tabView)

        self.centerContainer.set(backgroundColor: .clear)
        self.addChild(viewController: self.feedVC, toView: self.centerContainer)

        self.tabView.profileItem.didSelect = { [unowned self] in
            self.didTapProfile?()
        }

        self.tabView.postButtonView.button.didSelect { [unowned self] in
            self.didTapPost()
        }

        self.tabView.channelsItem.didSelect = { [unowned self] in
            self.didTapChannels?()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.vibrancyView.expandToSuperviewSize()

        let height = 70 + self.view.safeAreaInsets.bottom
        self.tabView.size = CGSize(width: self.view.width, height: height)
        self.tabView.centerOnX()
        self.tabView.pin(.bottom)

        self.centerContainer.expandToSuperviewSize()
        self.feedVC.view.expandToSuperviewSize()
    }

    func animateTabView(shouldShow: Bool) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.tabView.alpha = shouldShow ? 1.0 : 0.0
        }
    }

    private func didTapPost() {
        // do something 
    }
}
