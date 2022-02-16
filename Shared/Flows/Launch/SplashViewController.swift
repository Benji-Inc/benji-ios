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
        self.contentContainer.addSubview(self.animationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .loop

        self.contentContainer.addSubview(self.versionLabel)
        let version = Config.shared.environment.displayName.capitalized + " " + Config.shared.appVersion
        self.versionLabel.setText(version)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.animationView.size = CGSize(width: 18, height: 18)
        self.animationView.pinToSafeAreaRight()
        self.animationView.pinToSafeAreaBottom()

        let max = self.view.width - (Theme.contentOffset * 3) - self.animationView.width
        self.label.setSize(withWidth: max)
        self.label.match(.right, to: .left, of: self.animationView, offset: .negative(.standard))
        self.label.centerY  = self.animationView.centerY

        self.versionLabel.setSize(withWidth: self.view.width)
        self.versionLabel.pinToSafeAreaLeft()
        self.versionLabel.match(.bottom, to: .bottom, of: self.label)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.animationView.play()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Task {
            await self.startAnimatingText()
        }.add(to: self.autocancelTaskPool)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.animationView.stop()
    }

    @MainActor
    private func startAnimatingText() async {
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
                
        await self.startAnimatingText()
    }
}
