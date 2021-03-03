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
    private let vibrancyView = VibrancyView()
    private let vibrancyLabel = Label(font: .regular, textColor: .white)

    let centerContainer = View()
    let tabView = HomeTabView()

    var didTapProfile: CompletionOptional = nil
    var didTapChannels: CompletionOptional = nil

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.captureVC)
        self.vibrancyView.vibrancyEffectView.contentView.addSubview(self.vibrancyLabel)

        self.vibrancyLabel.setText("Coming soon. 👍")
        self.vibrancyLabel.textAlignment = .center

        self.view.addSubview(self.vibrancyView)
        self.view.addSubview(self.centerContainer)
        self.vibrancyView.vibrancyEffectView.contentView.addSubview(self.tabView)

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

        self.tabView.postButtonView.button.publisher(for: \.isHighlighted)
            .removeDuplicates()
            .mainSink { isHighlighted in
                UIView.animate(withDuration: Theme.animationDuration) {
                    //self.vibrancyView.show(blur: !isHighlighted)
                    self.vibrancyLabel.alpha = isHighlighted ? 1.0 : 0.0
                    self.feedVC.view.alpha = isHighlighted ? 0.0 : 1.0
                }

            }.store(in: &self.cancellables)

        self.captureVC.begin()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.captureVC.view.expandToSuperviewSize()
        self.vibrancyView.expandToSuperviewSize()

        self.vibrancyLabel.setSize(withWidth: self.view.width)
        self.vibrancyLabel.centerOnXAndY()

        let height = 70 + self.view.safeAreaInsets.bottom
        self.tabView.size = CGSize(width: self.view.width, height: height)
        self.tabView.centerOnX()
        self.tabView.pin(.bottom)

        self.centerContainer.frame = CGRect(x: 0,
                                            y: 0,
                                            width: self.view.width,
                                            height: self.view.height - height)
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
