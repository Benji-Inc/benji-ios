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

    let loadingView = AnimationView.with(animation: .loading)
    let label = ThemeLabel(font: .small)
    let versionLabel = ThemeLabel(font: .small)

    private let allMessages = ["Booting up", "Getting coffee", "Squishing bugs", "Saving trees",
                               "Finding purpose", "Doing math", "Painting pixels", "Kerning type",
                               "Doing dark mode", "Earning Jibs", "Raising money"]
    
    private var messages: [String] = []

    var text: Localized? {
        didSet {
            guard let text = self.text else { return }
            self.label.setText(text)
            self.view.layoutNow()
        }
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.messages = self.allMessages

        self.contentContainer.addSubview(self.label)
        self.contentContainer.addSubview(self.loadingView)
        self.loadingView.contentMode = .scaleAspectFit
        self.loadingView.loopMode = .loop

        self.contentContainer.addSubview(self.versionLabel)
        let version = Config.shared.environment.displayName.capitalized + " " + Config.shared.appVersion
        self.versionLabel.setText(version)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.loadingView.size = CGSize(width: 18, height: 18)
        self.loadingView.pinToSafeAreaRight()
        self.loadingView.pinToSafeAreaBottom()

        let max = self.view.width - (Theme.contentOffset * 3) - self.loadingView.width
        self.label.setSize(withWidth: max)
        self.label.match(.right, to: .left, of: self.loadingView, offset: .negative(.standard))
        self.label.centerY  = self.loadingView.centerY

        self.versionLabel.setSize(withWidth: self.view.width)
        self.versionLabel.pinToSafeAreaLeft()
        self.versionLabel.match(.bottom, to: .bottom, of: self.label)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.stopLoadAnimation()
    }

    func startLoadAnimation() {
        self.loadingView.play()

        Task {
            await self.animateText()
        }.add(to: self.autocancelTaskPool)
    }

    private func animateText() async {
        guard !Task.isCancelled else { return }

        await UIView.awaitAnimation(with: .fast, animations: {
            self.label.alpha = 0
        })

        if let message = self.messages.randomElement() {
            self.text = message
            self.messages.remove(object: message)
        } else {
            self.messages = self.allMessages
            let message = self.messages.randomElement()
            self.text = message
            self.messages.remove(object: message!)
        }

        await UIView.awaitAnimation(with: .fast, animations: {
            self.label.alpha = 1
        })

        await self.animateText()
    }

    func stopLoadAnimation() {
        self.loadingView.stop()
        self.autocancelTaskPool.cancelAndRemoveAll()
    }
}
