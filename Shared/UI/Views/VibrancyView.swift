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
    lazy var blurView = BlurView(effect: self.blurEffect)
    lazy var vibrancyEffect = UIVibrancyEffect(blurEffect: self.blurEffect)
    lazy var vibrancyEffectView = VisualEffectView(effect: self.vibrancyEffect)

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

    func show(blur: Bool) {
        self.blurView.effect = blur ? self.blurEffect : nil
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return true
    }
}

class BlurView: UIVisualEffectView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return true
    }
}

class VisualEffectView: UIVisualEffectView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return true
    }
}
