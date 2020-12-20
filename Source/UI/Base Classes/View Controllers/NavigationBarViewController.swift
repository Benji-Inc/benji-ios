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

    private(set) var animationView = AnimationView(name: "arrow")
    private(set) var backButton = Button()
    private(set) var titleLabel = Label(font: .regularBold)
    private(set) var descriptionLabel = Label(font: .small)
    /// Place all views under the lineView 
    private(set) var lineView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    let scrollView = UIScrollView()

    override func loadView() {
        self.view = self.scrollView
    }

    override func initializeViews() {
        super.initializeViews()

        self.animationView.transform = CGAffineTransform(rotationAngle: halfPi * -1)
        self.view.addSubview(self.backButton)
        self.backButton.set(style: .animation(view: self.animationView))
        self.backButton.didSelect { [unowned self] in
            self.didSelectBackButton()
        }

        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.descriptionLabel)
        self.view.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .background3)

        self.updateNavigationBar()
    }

    func updateNavigationBar(animateBackButton: Bool = true) {
        self.titleLabel.setText(self.getTitle())
        self.titleLabel.textAlignment = .center
        self.titleLabel.stringCasing = .uppercase

        self.descriptionLabel.setText(self.getDescription())
        self.descriptionLabel.textAlignment = .center

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
        self.backButton.left = Theme.contentOffset
        self.backButton.top = Theme.contentOffset

        self.titleLabel.setSize(withWidth: self.view.width * 0.8)
        self.titleLabel.centerY = self.backButton.centerY
        self.titleLabel.centerOnX()

        self.descriptionLabel.setSize(withWidth: self.view.width * 0.8)
        self.descriptionLabel.top = self.titleLabel.bottom + 20
        self.descriptionLabel.centerOnX()

        self.lineView.size = CGSize(width: self.view.width - (Theme.contentOffset * 2), height: 2)
        self.lineView.top = self.descriptionLabel.bottom + 20
        self.lineView.centerOnX()
    }

    // MARK: PUBLIC

    func getTitle() -> Localized {
        return LocalizedString.empty
    }

    func getDescription() -> Localized {
        return LocalizedString.empty
    }

    func didSelectBackButton() { }
}
