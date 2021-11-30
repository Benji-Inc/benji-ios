//
//  NavigationBarViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 10/20/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Lottie

class NavigationBarViewController: ViewController {

    private(set) var blurView = BlurView()
    private(set) var animationView = AnimationView.with(animation: .arrow)
    private(set) var backButton = Button()
    private(set) var titleLabel = Label(font: .display)
    private(set) var descriptionLabel = Label(font: .medium)

    let scrollView = UIScrollView()

    override func loadView() {
        self.view = self.scrollView
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.blurView)
        self.animationView.transform = CGAffineTransform(rotationAngle: halfPi * -1)
        self.view.addSubview(self.backButton)
        self.backButton.set(style: .animation(view: self.animationView))
        self.backButton.didSelect { [unowned self] in
            self.didSelectBackButton()
        }

        self.view.addSubview(self.titleLabel)
        self.titleLabel.textAlignment = .left
        self.view.addSubview(self.descriptionLabel)
        self.descriptionLabel.textAlignment = .left

        self.updateNavigationBar()
    }

    func updateNavigationBar(animateBackButton: Bool = true) {
        self.titleLabel.setText(self.getTitle())
        self.titleLabel.stringCasing = .uppercase
        self.descriptionLabel.setText(self.getDescription())

        self.animationView.alpha = self.shouldShowBackButton() ? 1.0 : 0.0

        if animateBackButton {
            delay(1.5) {
                self.animationView.play(fromFrame: 0, toFrame: 160, loopMode: nil, completion: nil)
            }
        }

        self.view.layoutNow()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.backButton.size = CGSize(width: 40, height: 40)
        self.backButton.left = Theme.contentOffset - 10
        self.backButton.top = Theme.contentOffset

        let maxWidth = self.view.width - Theme.contentOffset.doubled
        self.descriptionLabel.setSize(withWidth: maxWidth)
        self.titleLabel.setSize(withWidth: maxWidth)
        self.descriptionLabel.pinToSafeAreaLeft()
        self.titleLabel.pinToSafeAreaLeft()

        self.titleLabel.match(.top, to: .bottom, of: self.backButton)
        self.descriptionLabel.match(.top, to: .bottom, of: self.titleLabel, offset: .standard)

        self.blurView.expandToSuperviewSize()
    }

    // MARK: PUBLIC

    func shouldShowBackButton() -> Bool {
        return true
    }

    func getTitle() -> Localized {
        return LocalizedString.empty
    }

    func getDescription() -> Localized {
        return LocalizedString.empty
    }

    func didSelectBackButton() { }
}
