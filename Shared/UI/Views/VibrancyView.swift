//
//  VibrancyView.swift
//  Ours
//
//  Created by Benji Dodgson on 1/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class VibrancyView: View {

    lazy var blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
    lazy var blurView = UIVisualEffectView(effect: self.blurEffect)
    lazy var vibrancyEffect = UIVibrancyEffect(blurEffect: self.blurEffect)
    lazy var vibrancyEffectView = UIVisualEffectView(effect: self.vibrancyEffect)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.blurView)
        self.blurView.contentView.addSubview(self.vibrancyEffectView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.blurView.expandToSuperviewSize()
        self.vibrancyEffectView.expandToSuperviewSize()
    }
}
