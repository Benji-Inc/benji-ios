//
//  SplashViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 8/20/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie
import StoreKit
import Localization

class SplashViewController: FullScreenViewController, TransitionableViewController {

    var receivingPresentationType: TransitionType {
        return .fade
    }

    let animationView = AnimationView.with(animation: .loading)
    let label = ThemeLabel(font: .small)
    let versionLabel = ThemeLabel(font: .small)

    private let messages = ["Booting up", "Getting coffee", "Squishing bugs", "Saving trees", "Finding purpose", "Doing math", "Painting pixels", "Kerning type", "Doing darkmode", "Earning Jibs", "Raising money"]

    var text: Localized? {
        didSet {
            guard let text = self.text else { return }
            self.label.setText(text)
            self.view.layoutNow()
        }
    }
    
    override func initializeViews() {
        super.initializeViews()

        self.contentContainer.addSubview(self.label)
        self.contentContainer.addSubview(self.animationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .loop

        self.contentContainer.addSubview(self.versionLabel)
        let version = Config.shared.environment.displayName.capitalized + " " + Config.shared.appVersion
        self.versionLabel.setText(version)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.animateText()
    }
    
    func animateText() {
        UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveLinear) {
            self.text = self.messages.random()
        } completion: { _ in
            self.animateText()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.animationView.size = CGSize(width: 18, height: 18)
        self.animationView.pinToSafeAreaRight()
        self.animationView.pinToSafeAreaBottom()

        let max = self.view.width - (Theme.contentOffset * 3) - self.animationView.width
        self.label.setSize(withWidth: max)
        self.label.match(.right, to: .left, of: self.animationView, offset: .negative(.xtraLong))
        self.label.match(.bottom, to: .bottom, of: self.animationView)

        self.versionLabel.setSize(withWidth: self.view.width)
        self.versionLabel.pinToSafeAreaLeft()
        self.versionLabel.match(.bottom, to: .bottom, of: self.label)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.animationView.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.animationView.stop()
    }
}
