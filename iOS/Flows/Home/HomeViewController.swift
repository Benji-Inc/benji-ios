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

enum HomeContent: Equatable {
    case feed(FeedViewController)
    case channels(ChannelsViewController)
    case profile(ProfileViewController)
}

class HomeViewController: ViewController, TransitionableViewController {

    var receivingPresentationType: TransitionType {
        return .home
    }

    var transitionColor: Color {
        return .background1
    }

    lazy var feedVC = FeedViewController()
    lazy var channelsVC = ChannelsViewController()
    lazy var profileVC = ProfileViewController(with: User.current()!)

    let centerContainer = View()
    let tabView = HomeTabView()

    @Published var current: HomeContent?

    private(set) var currentCenterVC: UIViewController?

    override func initializeViews() {
        super.initializeViews()

        self.current = .feed(self.feedVC)

        self.view.set(backgroundColor: .background1)
        self.view.addSubview(self.centerContainer)
        self.view.addSubview(self.tabView)

        self.centerContainer.set(backgroundColor: .background1)

        self.$current
            .removeDuplicates()
            .mainSink { [weak self] (currentContent) in
            guard let `self` = self, let conent = currentContent else { return }
            self.switchTo(content: conent)
            self.tabView.updateTabItems(for: conent)
        }.store(in: &self.cancellables)

        self.tabView.profileItem.didSelect = { [unowned self] in
            self.current = .profile(self.profileVC)
        }

        self.tabView.postButtonView.button.didSelect { [unowned self] in
            self.current = .feed(self.feedVC)
        }

        self.tabView.channelsItem.didSelect = { [unowned self] in
            self.current = .channels(self.channelsVC)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let height = 70 + self.view.safeAreaInsets.bottom
        self.tabView.size = CGSize(width: self.view.width, height: height)
        self.tabView.centerOnX()
        self.tabView.pin(.bottom)

        self.centerContainer.expandToSuperviewSize()
        self.currentCenterVC?.view.expandToSuperviewSize()
    }

    private func switchTo(content: HomeContent) {

        UIView.animate(withDuration: Theme.animationDuration, animations: {
            self.currentCenterVC?.view.alpha = 0
        }) { (completed) in

            self.currentCenterVC?.removeFromParentSuperview()
            var newContentVC: UIViewController?

            switch content {
            case .feed(let vc):
                newContentVC = vc
            case .channels(let vc):
                newContentVC = vc
            case .profile(let vc):
                newContentVC = vc
            }

            self.currentCenterVC = newContentVC

            if let contentVC = self.currentCenterVC {
                self.addChild(viewController: contentVC, toView: self.centerContainer)
            }

            self.view.setNeedsLayout()

            UIView.animate(withDuration: Theme.animationDuration) {
                self.currentCenterVC?.view.alpha = 1
            }
        }
    }
}
