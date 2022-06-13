//
//  VibrancyView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class VibrancyView: BaseView {

    let blurView = DarkBlurView()
    let effectView = VisualEffectView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.blurView)
        self.blurView.contentView.addSubview(self.effectView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.blurView.expandToSuperviewSize()
        self.effectView.expandToSuperviewSize()
    }

    func show(blur: Bool) {
        self.blurView.effect = blur ? Theme.blurEffect : nil
    }
}

class DarkBlurView: UIVisualEffectView {

    let blurEffect: UIBlurEffect

    init() {
        self.blurEffect = Theme.darkBlurEffect
        super.init(effect: Theme.darkBlurEffect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showBlur(_ show: Bool) {
        self.effect = show ? self.blurEffect : nil
    }
}

class BlurView: UIVisualEffectView {

    let blurEffect: UIBlurEffect

    init() {
        self.blurEffect = Theme.blurEffect
        super.init(effect: Theme.blurEffect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showBlur(_ show: Bool) {
        self.effect = show ? self.blurEffect : nil
    }
}

class VisualEffectView: UIVisualEffectView {

    init() {
        super.init(effect: Theme.darkBlurEffect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
