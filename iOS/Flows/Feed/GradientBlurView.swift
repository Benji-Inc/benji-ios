//
//  GradientBlurView.swift
//  Ours
//
//  Created by Benji Dodgson on 6/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class GradientBlurView: GradientView {

    lazy var blurEffect = UIBlurEffect(style: .systemMaterialDark)
    lazy var blurView = BlurView(effect: self.blurEffect)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.blurView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.blurView.expandToSuperviewSize()
    }
}
