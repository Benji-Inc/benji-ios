//
//  DemoView.swift
//  Ours
//
//  Created by Benji Dodgson on 6/5/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie

class DemoView: View {

    let animationView = AnimationView()
    let label = Label(font: .small)
    private let demo: KeyboardDemoViewController.DemoType

    init(with demo: KeyboardDemoViewController.DemoType) {
        self.demo = demo
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.label)
        self.addSubview(self.animationView)

        self.label.setText(self.demo.instruction)
        self.label.textAlignment = .center

        self.animationView.load(animation: self.demo.animation)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.width - Theme.contentOffset.doubled)
        self.label.centerOnX()
        self.label.pinToSafeArea(.bottom, padding: Theme.contentOffset.doubled)

        self.animationView.width = self.width - Theme.contentOffset.doubled
        self.animationView.height = self.height * 0.4
        self.animationView.centerOnX()
        self.animationView.match(.bottom, to: .top, of: self.label, offset: -Theme.contentOffset.half)
    }
}
