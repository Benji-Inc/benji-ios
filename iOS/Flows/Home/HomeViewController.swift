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
    lazy var captureVC = PostCreationViewController()
    let vibrancyView = HomeVibrancyView()
    let tabView = HomeTabView()
    let exitButton = ImageViewButton()

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

        self.view.addSubview(self.exitButton)
        self.exitButton.imageView.image = UIImage(systemName: "xmark")!
        self.exitButton.didSelect { [unowned self] in
            self.captureVC.reset()
            self.tabView.state = .home
        }

        self.view.addSubview(self.tabView)

        self.tabView.didSelectProfile = { [unowned self] in
            self.didTapProfile?()
        }

        self.tabView.postButtonView.button.didSelect { [unowned self] in
            self.didTapPost()
        }

        self.tabView.didSelectChannels = { [unowned self] in
            self.didTapChannels?()
        }

        self.tabView.didSelectFlip = { [unowned self] in
           // self.didTapChannels?()
        }

        self.tabView.didSelectPhotoLibrary = { [unowned self] in
            //self.didTapChannels?()
        }

        self.feedCollectionVC.collectionViewManager.$onSelectedItem.mainSink { (cellItem) in
            guard let item = cellItem?.item as? Feed else { return }
            self.didTapFeed?(item)
        }.store(in: &self.cancellables)

        self.tabView.$state.mainSink { state in
            self.exitButton.alpha = state == .home ? 0.0 : 1.0
            self.vibrancyView.show(blur: state == .home)
        }.store(in: &self.cancellables)

        self.captureVC.didShowImage = { [unowned self] in 
            self.tabView.state = .confirm
        }

//        self.vibrancyView.tabView.postButtonView.button.publisher(for: \.isHighlighted)
//            .removeDuplicates()
//            .mainSink { isHighlighted in
//                UIView.animate(withDuration: Theme.animationDuration) {
//                    self.vibrancyView.show(blur: !isHighlighted)
//                    self.view.layoutNow()
//                }
//
//            }.store(in: &self.cancellables)

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

        let height = 70 + self.view.safeAreaInsets.bottom
        self.tabView.size = CGSize(width: self.view.width, height: height)
        self.tabView.centerOnX()
        self.tabView.pin(.bottom)

        self.exitButton.squaredSize = 50
        self.exitButton.match(.top, to: .top, of: self.vibrancyView, offset: Theme.contentOffset)
        self.exitButton.pin(.right, padding: Theme.contentOffset)
    }

    func animate(show: Bool) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.tabView.alpha = show ? 1.0 : 0.0
            self.feedCollectionVC.view.alpha = show ? 1.0 : 0.0
        }
    }

    private func didTapPost() {
        switch self.tabView.state {
        case .home:
            self.vibrancyView.show(blur: false)
            self.tabView.state = .post
        case .post:
            self.captureVC.capturePhoto()
        case .confirm:
            self.captureVC.createPost()
        }
    }
}
