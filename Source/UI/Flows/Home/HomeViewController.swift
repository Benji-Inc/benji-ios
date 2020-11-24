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
import ReactiveSwift

enum HomeContent: Equatable {
    case feed(FeedViewController)
    case channels(ChannelsViewController)
    case profile(ProfileViewController)
}

protocol HomeViewControllerDelegate: class {
    func homeViewDidTapAdd(_ controller: HomeViewController)
}

typealias HomeDelegate = HomeViewControllerDelegate

class HomeViewController: ViewController {

    unowned let delegate: HomeDelegate

    lazy var feedVC = FeedViewController()
    lazy var channelsVC = ChannelsViewController()
    lazy var profileVC = ProfileViewController(with: User.current()!)

    let centerContainer = View()
    let tabView = HomeTabView()

    lazy var currentContent = MutableProperty<HomeContent>(.feed(self.feedVC))
    private(set) var currentCenterVC: UIViewController?

    init(with delegate: HomeDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init?(withObject object: DeepLinkable) {
        fatalError("init(withObject:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)
        self.view.addSubview(self.tabView)
        self.view.addSubview(self.centerContainer)
        self.centerContainer.set(backgroundColor: .background1)

        self.currentContent.producer
            .skipRepeats()
            .on(value:  { [unowned self] (contentType) in
                self.switchContent()
                self.tabView.updateTabItems(for: contentType)
            }).start()

        self.tabView.profileItem.didSelect = { [unowned self] in
            self.currentContent.value = .profile(self.profileVC)
        }

        self.tabView.feedItem.didSelect = { [unowned self] in
            self.currentContent.value = .feed(self.feedVC)
        }

        self.tabView.channelsItem.didSelect = { [unowned self] in
            self.currentContent.value = .channels(self.channelsVC)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let height = 70 + self.view.safeAreaInsets.bottom
        self.tabView.size = CGSize(width: self.view.width, height: height)
        self.tabView.centerOnX()
        self.tabView.pin(.bottom)

        self.centerContainer.size = CGSize(width: self.view.width + 10,
                                           height: self.view.safeAreaRect.height - self.tabView.height)
        self.centerContainer.match(.bottom, to: .top, of: self.tabView, offset: 20)
        self.centerContainer.centerOnX()

        self.centerContainer.layer.cornerRadius = 25
        self.centerContainer.layer.cornerCurve = CALayerCornerCurve.continuous
        self.centerContainer.layer.shadowColor = UIColor.black.cgColor
        self.centerContainer.layer.shadowOpacity = 0.6
        self.centerContainer.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.centerContainer.layer.shadowRadius = 10
        self.centerContainer.layer.masksToBounds = false

        self.currentCenterVC?.view.frame = CGRect(x: 5,
                                                  y: 0,
                                                  width: self.centerContainer.width - 10,
                                                  height: self.centerContainer.height)
    }

    private func switchContent() {

        UIView.animate(withDuration: Theme.animationDuration, animations: {
            self.currentCenterVC?.view.alpha = 0
        }) { (completed) in

            self.currentCenterVC?.removeFromParentSuperview()
            var newContentVC: UIViewController?

            switch self.currentContent.value {
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
