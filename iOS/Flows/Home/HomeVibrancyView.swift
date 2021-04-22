//
//  RitualVibrancyView.swift
//  Ours
//
//  Created by Benji Dodgson on 3/5/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Lottie

class HomeVibrancyView: VibrancyView {

    let animationView = AnimationView(name: "scroll_down")
    let label = Label(font: .small)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.vibrancyEffectView.contentView.addSubview(self.animationView)
        self.animationView.loopMode = .loop
        self.animationView.alpha  = 0
        self.vibrancyEffectView.contentView.addSubview(self.label)

        self.label.setText("Swipe down to view archives.")
        self.label.alpha = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.animationView.squaredSize = 40
        self.animationView.centerOnX()
        self.animationView.centerY = self.halfHeight * 0.8

        self.label.setSize(withWidth: self.width - Theme.contentOffset.doubled)
        self.label.match(.top, to: .bottom, of: self.animationView, offset: Theme.contentOffset.half)
        self.label.centerOnX()
    }

    func animateScroll() {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.label.alpha = 1.0
            self.animationView.alpha = 1.0
        } completion: { _ in
            self.animationView.play()

            UIView.animate(withDuration: Theme.animationDuration, delay: 4.0, options: []) {
                self.label.alpha = 0
                self.animationView.alpha = 0
            } completion: { _ in }
        }
    }
}
