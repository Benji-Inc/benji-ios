//
//  WaitlistViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/17/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROLocalization
import StoreKit

class WaitlistViewController: ViewController, Sizeable {

    let positionLabel = Label(font: .small)
    let remainingLabel = Label(font: .display)

    lazy var skOverlay: SKOverlay = {
        let config = SKOverlay.AppClipConfiguration(position: .bottom)
        let overlay = SKOverlay(configuration: config)
        overlay.delegate = self
        return overlay
    }()

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.positionLabel)
        self.view.addSubview(self.remainingLabel)

        #if APPCLIP
        if User.current()?.status == .inactive {
            self.loadUpgrade()
        } else {
            self.loadWaitlist()
        }
        #endif
    }

    private func loadWaitlist() {
        if let position = User.current()?.quePosition {
            let positionString = LocalizedString(id: "", arguments: [String(position)], default: "Your positon is: @(position)")
            self.positionLabel.setText(positionString)

            PFConfig.getInBackground { [weak self]( config, error) in
                guard let `self` = self else { return }

                if let max = config?.object(forKey: "maxQuePosition") as? Int,
                   let claimed = config?.object(forKey: "claimedPositon") as? Int {

                    let remaining = (position + claimed) - max

                    self.remainingLabel.setText(String(remaining))
                    self.view.layoutNow()
                }
            }
        }
    }

    private func loadUpgrade() {
        self.positionLabel.setText("Your in!")
        self.displayAppUpdateOverlay()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.remainingLabel.setSize(withWidth: self.view.width)
        self.remainingLabel.centerOnX()
        self.remainingLabel.bottom = self.view.halfHeight * 0.8

        self.positionLabel.setSize(withWidth: self.view.width)
        self.positionLabel.match(.top, to: .bottom, of: self.remainingLabel, offset: 20)
        self.positionLabel.centerOnX()
    }
}

extension WaitlistViewController: SKOverlayDelegate {

    func displayAppUpdateOverlay() {
        guard let window = UIWindow.topWindow(), let scene = window.windowScene else { return }
        self.skOverlay.present(in: scene)
    }

    func storeOverlayWillStartPresentation(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {
    }

    func storeOverlayWillStartDismissal(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {
    }
}
