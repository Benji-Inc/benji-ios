//
//  SplashViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 8/20/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie
import TMROLocalization
import StoreKit

class SplashViewController: FullScreenViewController, TransitionableViewController {

    var receivingPresentationType: TransitionType {
        return .fade
    }

    var transitionColor: Color {
        return .background1
    }

    let animationView = AnimationView.with(animation: .loading)
    let label = Label(font: .small)
    let versionLabel = Label(frame: .zero, font: .small, textColor: .background2)

    private let messages = ["Booting up", "Getting coffee", "Connecting", "Saving a tree", "Finding purpose", "Doing math"]

    var text: Localized? {
        didSet {
            guard let text = self.text else { return }
            self.label.setText(text)
            self.label.setTextColor(.purple)
            self.view.layoutNow()
        }
    }
    
    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)

        self.contentContainer.addSubview(self.label)
        self.contentContainer.addSubview(self.animationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .loop

        self.contentContainer.addSubview(self.versionLabel)
        let version = Config.shared.environment.displayName.capitalized + " " + Config.shared.appVersion
        self.versionLabel.setText(version)

        self.text = self.messages.random()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.animationView.size = CGSize(width: 18, height: 18)
        self.animationView.pin(.right, padding: Theme.contentOffset)
        self.animationView.pinToSafeArea(.bottom, padding: 5)

        let max = self.view.width - (Theme.contentOffset * 3) - self.animationView.width
        self.label.setSize(withWidth: max)
        self.label.match(.right, to: .left, of: self.animationView, offset: Theme.contentOffset * -1)
        self.label.match(.bottom, to: .bottom, of: self.animationView)

        self.versionLabel.setSize(withWidth: self.view.width)
        self.versionLabel.pin(.left, padding: Theme.contentOffset)
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
