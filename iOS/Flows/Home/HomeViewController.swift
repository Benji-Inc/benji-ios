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

    lazy var feedCollectionVC = FeedCollectionViewController()
    lazy var captureVC = ImageCaptureViewController()
    let vibrancyView = HomeVibrancyView()

    var didTapProfile: CompletionOptional = nil
    var didTapChannels: CompletionOptional = nil
    var didTapAddRitual: CompletionOptional = nil
    var didTapFeed: ((Feed) -> Void)? = nil

    private var topOffset: CGFloat?

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)

        self.addChild(viewController: self.feedCollectionVC)
        self.addChild(viewController: self.captureVC)

        self.view.addSubview(self.vibrancyView)

        self.self.captureVC.view.layer.cornerRadius = 20
        self.captureVC.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.captureVC.view.layer.masksToBounds = true

        self.vibrancyView.layer.cornerRadius = 20
        self.vibrancyView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.vibrancyView.layer.masksToBounds = true

        self.vibrancyView.tabView.profileItem.didSelect = { [unowned self] in
            self.didTapProfile?()
        }

        self.vibrancyView.tabView.postButtonView.button.didSelect { [unowned self] in
            self.didTapPost()
        }

        self.vibrancyView.tabView.channelsItem.didSelect = { [unowned self] in
            self.didTapChannels?()
        }

        self.feedCollectionVC.collectionViewManager.$onSelectedItem.mainSink { (cellItem) in
            guard let item = cellItem?.item as? Feed else { return }
            self.didTapFeed?(item)
        }.store(in: &self.cancellables)

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

        self.feedCollectionVC.view.expandToSuperviewWidth()
        self.feedCollectionVC.view.height = FeedCollectionViewController.height
        self.feedCollectionVC.view.pinToSafeArea(.top, padding: 0)

        self.captureVC.view.height = self.view.height - self.feedCollectionVC.view.bottom - Theme.contentOffset
        self.captureVC.view.expandToSuperviewWidth()
        self.captureVC.view.centerOnX()
        self.captureVC.view.match(.top, to: .bottom, of: self.feedCollectionVC.view, offset: Theme.contentOffset)
        self.vibrancyView.frame = self.captureVC.view.frame
    }

    func animate(show: Bool) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.vibrancyView.tabView.alpha = show ? 1.0 : 0.0
        }
    }

    private func didTapPost() {
        // do something 
    }
}
