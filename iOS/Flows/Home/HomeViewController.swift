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

    lazy var noticesCollectionVC = NoticesCollectionViewController()

    let tabView = HomeTabView()

    var didTapProfile: CompletionOptional = nil
    var didTapChannels: CompletionOptional = nil
    var isMenuPresenting: Bool = false

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)

        self.addChild(viewController: self.noticesCollectionVC)

        self.view.addSubview(self.tabView)

        self.tabView.didSelectProfile = { [unowned self] in
            self.didTapProfile?()
        }

        self.tabView.didSelectChannels = { [unowned self] in
            self.didTapChannels?()
        }

        self.tabView.$state.mainSink { state in
            UIView.animate(withDuration: Theme.animationDuration) {
                self.view.layoutNow()
            }
        }.store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.noticesCollectionVC.view.expandToSuperviewWidth()
        self.noticesCollectionVC.view.height = NoticesCollectionViewController.height
        self.noticesCollectionVC.view.pinToSafeArea(.top, padding: Theme.contentOffset)


        let height = 70 + self.view.safeAreaInsets.bottom
        self.tabView.size = CGSize(width: self.view.width, height: height)
        self.tabView.centerOnX()

        self.tabView.pinToSafeArea(.bottom, padding: Theme.contentOffset)
    }

    func animate(show: Bool) {
        self.isMenuPresenting = !show
        UIView.animate(withDuration: Theme.animationDuration) {
            self.tabView.alpha = show ? 1.0 : 0.0
            self.noticesCollectionVC.view.alpha = show ? 1.0 : 0.0
        }
    }
}
