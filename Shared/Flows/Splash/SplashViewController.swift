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

class SplashViewController: FullScreenViewController {

    let animationView = AnimationView(name: "loading")
    let label = Label(font: .small)
    let versionLabel = Label(frame: .zero, font: .small, textColor: .background2)

    private let messages = ["Booting up", "Getting coffee", "Connecting", "Saving a tree", "Finding purpose", "Doing math"]

    var text: Localized? {
        didSet {
            guard let text = self.text else { return }
            self.label.setText(text)
            self.label.setTextColor(.background4)
            self.view.layoutNow()
        }
    }

    lazy var skOverlay: SKOverlay = {
        let config = SKOverlay.AppClipConfiguration(position: .bottom)
        let overlay = SKOverlay(configuration: config)
        overlay.delegate = self
        return overlay
    }()
    
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

extension SplashViewController: SKOverlayDelegate {

    func displayAppUpdateOverlay() {
        guard let window = UIWindow.topWindow(), let scene = window.windowScene else { return }
        self.skOverlay.present(in: scene)
    }

    func storeOverlayWillStartPresentation(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {
        self.animationView.stop()
        self.label.alpha = 0
    }

    func storeOverlayWillStartDismissal(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {
        self.animationView.play()
        self.label.alpha = 1
    }
}
