//
//  RitualVibrancyView.swift
//  Ours
//
//  Created by Benji Dodgson on 3/5/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class HomeVibrancyView: VibrancyView {

    private let darkBlur = UIBlurEffect(style: .dark)
    let tabView = HomeTabView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.vibrancyEffectView.contentView.addSubview(self.tabView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let height = 70 + self.safeAreaInsets.bottom
        self.tabView.size = CGSize(width: self.width, height: height)
        self.tabView.centerOnX()
        self.tabView.pin(.bottom)
    }
}
